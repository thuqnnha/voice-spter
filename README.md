# Voice Supporter

Dự án nhận diện lời nói sử dụng **ESP32C3 Supermini + Flutter + TensorFlow Lite**.

---

## Cấu trúc thư mục

```text
voice-spter/
├── software/   # Ứng dụng Flutter
├── firmware/   # Firmware ESP32
├── hardware/   # Sơ đồ phần cứng
```
---

## Tổng quan hệ thống

Piezo Sensor + Micro sensor → ESP32C3 → BLE → Flutter → TensorFlow Lite → TTS

---

## Huấn luyện mô hình

### 1. Thu thập dữ liệu

Thư mục:

```text
firmware/dataset/
├── dataset.ino
├── save_log.py
├── merge.py
├── train.py
└── export_scaler.py
```

#### Bước 1: Nạp firmware

Mở `dataset.ino`, chỉnh label cần thu thập:

| Label | Từ khóa |
| ----- | ------- |
| 0     | Không   |
| 1     | Đúng    |
| 2     | Sai     |

Sau đó nạp chương trình vào ESP32.

#### Bước 2: Ghi dữ liệu

Mở `save_log.py` và chỉnh cổng COM:

```python
PORT = "COM20"
```

Chạy chương trình:

```bash
python save_log.py
```

Chọn label tương ứng:

```text
0 = Không
1 = Đúng
2 = Sai
```

Giữ nút trên thiết bị và phát âm từ khóa cần thu thập, sau đó nhả nút để lưu dữ liệu.

Dữ liệu sẽ được lưu vào các file:

```text
khong.csv
dung.csv
sai.csv
```

Lặp lại quá trình trên cho tất cả các lớp dữ liệu.

---

### 2. Tạo tập dữ liệu

Sau khi thu thập xong:

```bash
python merge.py
```

Chương trình sẽ:

* Gộp các file CSV
* Làm sạch dữ liệu
* Cân bằng số lượng mẫu
* Trộn ngẫu nhiên dữ liệu

Kết quả:

```text
dataset.csv
```

---

### 3. Huấn luyện mô hình

Chạy:

```bash
python train.py
```

Quá trình này sẽ:

* Chuẩn hóa dữ liệu
* Chia tập Train/Test (80/20)
* Huấn luyện mô hình Neural Network
* Đánh giá độ chính xác
* Xuất mô hình TensorFlow Lite

Kết quả:

```text
model.h5
model.tflite
scaler.save
```

---

### 4. Xuất tham số chuẩn hóa

Chạy:

```bash
python export_scaler.py
```

Kết quả:

```text
scaler_params.json
```

---

### 5. Triển khai lên Flutter

Sao chép các file sau:

```text
model.tflite
scaler_params.json
```

vào thư mục:

```text
software/assets/
```

---

## Workflow

```text
dataset.ino
      ↓
save_log.py
      ↓
CSV theo từng lớp
      ↓
merge.py
      ↓
dataset.csv
      ↓
train.py
      ↓
model.tflite
scaler.save
      ↓
export_scaler.py
      ↓
scaler_params.json
      ↓
Flutter App
```

## Sử dụng hệ thống

### 1. Nạp firmware ESP32

Mở thư mục:

```text
firmware/esp32_voice/
```

Nạp chương trình:

```text
esp32_voice.ino
```

vào ESP32.

---

### 2. Cập nhật mô hình cho ứng dụng Flutter

Sau khi huấn luyện xong, sao chép các file vừa được:

```text
model.tflite
scaler_params.json
```

vào thư mục:

```text
software/assets/
```

Đồng thời cập nhật tên file trong `InferenceService` nếu cần:

```dart
rootBundle.loadString('assets/scaler_params.json');

Interpreter.fromAsset('assets/model.tflite');
```

---

### 3. Chạy ứng dụng Flutter

Mở thư mục:

```text
software/
```

Chạy các lệnh:

```bash
flutter clean
flutter pub get
flutter run
```

---

### 4. Kết nối thiết bị

1. Bật Bluetooth trên điện thoại.
2. Nhấn **SCAN DEVICE** để kết nối thiết bị.

---

### 5. Nhận diện lời nói

Sau khi kết nối thành công:

1. Giữ nút nhấn trên thiết bị.
2. Phát âm từ khóa cần nhận diện.
3. Nhả nút để gửi dữ liệu tới ứng dụng.
4. Ứng dụng sẽ:

   * Nhận dữ liệu BLE
   * Chuẩn hóa dữ liệu đầu vào
   * Chạy mô hình TensorFlow Lite
   * Hiển thị kết quả dự đoán
   * Phát âm kết quả bằng TTS

Các nhãn được hỗ trợ:

| Kết quả | Ý nghĩa              |
| ------- | ---------------------|
| Không   | Nhận diện từ "Không" |
| Đúng    | Nhận diện từ "Đúng"  |
| Sai     | Nhận diện từ "Sai"   |

---

## Workflow hệ thống

```text
Piezo + Microphone
          ↓
        ESP32
          ↓
      Bluetooth
          ↓
     Flutter App
          ↓
   StandardScaler
          ↓
   TensorFlow Lite
          ↓
     Prediction
          ↓
    Text To Speech
```
