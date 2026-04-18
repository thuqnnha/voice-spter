#include <Arduino.h>

#define PIEZO_PIN   1
#define MIC_PIN     0
#define WINDOW_SIZE 64

// ===== CHỌN LABEL Ở ĐÂY =====
// 0 = silent
// 1 = co
// 2 = khong
int LABEL = 2;

// ---- Feature extraction ----
struct SensorFeatures {
  float piezo_rms;
  float piezo_peak;
  float mic_rms;
  float mic_zcr;
  float mic_energy;
  float ratio;
};

SensorFeatures extractFeatures(int piezoPin, int micPin, int n) {
  long pSumSq = 0, mSumSq = 0;
  int  pPeak  = 0;
  int  mZcr   = 0;
  int  prevM  = 0;

  for (int i = 0; i < n; i++) {
    int p = analogRead(piezoPin) - 2048;
    int m = analogRead(micPin)   - 2048;

    pSumSq += (long)p * p;
    mSumSq += (long)m * m;

    if (abs(p) > pPeak) pPeak = abs(p);

    if (i > 0 && ((prevM >= 0) != (m >= 0))) mZcr++;
    prevM = m;

    delayMicroseconds(125); // ~8kHz
  }

  float pRMS = sqrt((float)pSumSq / n);
  float mRMS = sqrt((float)mSumSq / n);

  SensorFeatures f;
  f.piezo_rms  = pRMS;
  f.piezo_peak = (float)pPeak;
  f.mic_rms    = mRMS;
  f.mic_zcr    = (float)mZcr / n;
  f.mic_energy = (mRMS > 1) ? log10(mRMS) : 0.0f;
  f.ratio      = (mRMS > 1) ? pRMS / mRMS : 0.0f;

  return f;
}

void setup() {
  Serial.begin(115200);

  analogReadResolution(12);
  analogSetAttenuation(ADC_11db);

  delay(2000); // chờ mở serial

  // Header CSV
  Serial.println("piezo_rms,piezo_peak,mic_rms,mic_zcr,mic_energy,ratio,label");
}

void loop() {
  SensorFeatures f = extractFeatures(PIEZO_PIN, MIC_PIN, WINDOW_SIZE);

  Serial.printf("%.2f,%.2f,%.2f,%.3f,%.2f,%.3f,%d\n",
    f.piezo_rms, f.piezo_peak,
    f.mic_rms, f.mic_zcr,
    f.mic_energy, f.ratio,
    LABEL
  );

  delay(100); // 10 samples/s
}