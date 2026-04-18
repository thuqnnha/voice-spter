#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>

// ===== PIN =====
#define PIEZO_PIN   1
#define MIC_PIN     0
#define WINDOW_SIZE 64

// ===== BLE UUID =====
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

BLEServer*         pServer         = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// ===== BLE Callbacks =====
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* s)    { deviceConnected = true;  Serial.println("✅ Client connected"); }
  void onDisconnect(BLEServer* s) {
    deviceConnected = false;
    Serial.println("❌ Client disconnected, restarting advertising...");
    BLEDevice::startAdvertising();
  }
};

// ===== Feature Extraction (giống dataset.ino) =====
struct Features {
  float piezo_rms;
  float piezo_peak;
  float mic_rms;
  float mic_zcr;
  float mic_energy;
  float ratio;
};

Features extractFeatures() {
  long pSumSq = 0, mSumSq = 0;
  int  pPeak  = 0;
  int  mZcr   = 0;
  int  prevM  = 0;

  for (int i = 0; i < WINDOW_SIZE; i++) {
    int p = analogRead(PIEZO_PIN) - 2048;
    int m = analogRead(MIC_PIN)   - 2048;

    pSumSq += (long)p * p;
    mSumSq += (long)m * m;

    if (abs(p) > pPeak) pPeak = abs(p);
    if (i > 0 && ((prevM >= 0) != (m >= 0))) mZcr++;
    prevM = m;

    delayMicroseconds(125); // ~8kHz
  }

  float pRMS = sqrt((float)pSumSq / WINDOW_SIZE);
  float mRMS = sqrt((float)mSumSq / WINDOW_SIZE);

  Features f;
  f.piezo_rms  = pRMS;
  f.piezo_peak = (float)pPeak;
  f.mic_rms    = mRMS;
  f.mic_zcr    = (float)mZcr / WINDOW_SIZE;
  f.mic_energy = (mRMS > 1.0f) ? log10(mRMS) : 0.0f;
  f.ratio      = (mRMS > 1.0f) ? pRMS / mRMS : 0.0f;

  return f;
}

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  // ===== BLE Init =====
  BLEDevice::init("ESP32-Sensor"); // Giữ tên cũ để app tìm được
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  BLEDevice::startAdvertising();
  Serial.println("🔵 BLE ready, waiting for connection...");
}

void loop() {
  if (deviceConnected) {
    Features f = extractFeatures();

    // Pack 6 float32 → 24 bytes
    float payload[6] = {
      f.piezo_rms,
      f.piezo_peak,
      f.mic_rms,
      f.mic_zcr,
      f.mic_energy,
      f.ratio
    };

    uint8_t buf[24];
    memcpy(buf, payload, 24);

    pCharacteristic->setValue(buf, 24);
    pCharacteristic->notify();

    Serial.printf("📡 Sent: rms=%.2f peak=%.2f mic_rms=%.2f zcr=%.3f energy=%.2f ratio=%.3f\n",
      f.piezo_rms, f.piezo_peak, f.mic_rms, f.mic_zcr, f.mic_energy, f.ratio);
  }

  delay(300); // ~3 predictions/giây
}
