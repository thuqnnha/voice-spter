#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <math.h>

// ===== PIN CONFIG =====
#define PIEZO_PIN   1
#define MIC_PIN     0
#define BTN_PIN     10       // Nút nhấn: nối BTN_PIN → GND (dùng INPUT_PULLUP)
#define LED_PIN     8       // LED built-in ESP32 C3 SuperMini
#define WINDOW_SIZE 64

// ===== BLE UUID =====
#define SERVICE_UUID        "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define CHARACTERISTIC_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

BLEServer*         pServer         = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// ===== BLE Callbacks =====
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* s) {
    deviceConnected = true;
    Serial.println("✅ Client connected");
    digitalWrite(LED_PIN, HIGH);
  }
  void onDisconnect(BLEServer* s) {
    deviceConnected = false;
    Serial.println("❌ Disconnected, advertising...");
    digitalWrite(LED_PIN, LOW);
    BLEDevice::startAdvertising();
  }
};

// ===== Feature Struct =====
struct Features {
  float piezo_rms;
  float piezo_peak;
  float mic_rms;
  float mic_zcr;
  float mic_energy;
  float ratio;
};

// ===== Feature Extraction =====
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

// ===== Button Debounce =====
bool     btnState     = false;
bool     lastRaw      = false;
uint32_t lastDebounce = 0;
const uint32_t DEBOUNCE_MS = 30;

bool readButton() {
  bool raw = (digitalRead(BTN_PIN) == LOW); // LOW = pressed (INPUT_PULLUP)
  if (raw != lastRaw) {
    lastDebounce = millis();
    lastRaw = raw;
  }
  if ((millis() - lastDebounce) > DEBOUNCE_MS) {
    btnState = raw;
  }
  return btnState;
}

// ===== State Machine =====
enum State { IDLE, RECORDING, SEND };
State state = IDLE;

float acc[6]   = {0};
int sampleCount = 0;

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  pinMode(BTN_PIN, INPUT_PULLUP);
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  BLEDevice::init("ESP32-Sensor");
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
  Serial.println("🔵 BLE ready. Hold button to record, release to send.");
}

void loop() {
  bool btn = readButton();

  switch (state) {

    case IDLE:
      if (btn && deviceConnected) {
        memset(acc, 0, sizeof(acc));
        sampleCount = 0;
        state = RECORDING;
        Serial.println("🎙️  Recording...");
        // Blink LED nhanh khi đang ghi
        digitalWrite(LED_PIN, LOW);
      }
      break;

    case RECORDING:
      if (btn) {
        // Blink LED ~5Hz để báo đang thu
        digitalWrite(LED_PIN, (millis() / 100) % 2);

        Features f = extractFeatures();
        acc[0] += f.piezo_rms;
        acc[1] += f.piezo_peak;
        acc[2] += f.mic_rms;
        acc[3] += f.mic_zcr;
        acc[4] += f.mic_energy;
        acc[5] += f.ratio;
        sampleCount++;
      } else {
        // Button released → send
        digitalWrite(LED_PIN, deviceConnected ? HIGH : LOW);
        state = SEND;
      }
      break;

    case SEND:
      if (sampleCount > 0 && deviceConnected) {
        float payload[6];
        for (int i = 0; i < 6; i++) payload[i] = acc[i] / sampleCount;

        uint8_t buf[24];
        memcpy(buf, payload, 24);
        pCharacteristic->setValue(buf, 24);
        pCharacteristic->notify();

        Serial.printf("📡 Sent (%d samples avg): piezo_rms=%.2f peak=%.2f mic_rms=%.2f zcr=%.3f energy=%.2f ratio=%.3f\n",
          sampleCount, payload[0], payload[1], payload[2], payload[3], payload[4], payload[5]);
      } else if (!deviceConnected) {
        Serial.println("⚠️  Not connected, data discarded");
      }
      state = IDLE;
      break;
  }

  delay(10);
}
