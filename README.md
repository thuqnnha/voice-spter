# Voice Supporter

Dự án nhận diện giọng nói sử dụng **ESP32C3 Supermini + Flutter + TensorFlow Lite**.

---

## Cấu trúc

```bash
voice-spter/
├── software/   # App Flutter
├── firmware/   # Code ESP32C3 SP
```

---

## Software

Chức năng:

* Kết nối ESP32C3 SM qua BLE
* Nhận dữ liệu cảm biến
* Chạy model TFLite
* Hiển thị kết quả
* Phát âm bằng TTS

Kiến trúc: MVVM

Chạy app:

```bash
cd software
flutter pub get
flutter run
```

---

## Firmware 

Chức năng:

* Đọc dữ liệu từ piezo sensor + max9814
* Trích xuất feature
* Gửi dữ liệu qua BLE

---

## Model

* Input: 6 features
* Output:

  * 0: silent
  * 1: yes
  * 2: no

---

## Workflow

ESP32 → BLE → Flutter → TFLite → Result

---

## Author

* Hà Đức Thuận
