import serial
import sys
import time

# ===== CONFIG =====
PORT     = 'COM20'
BAUD     = 115200
LABEL    = int(input("Nhập label (0-3): "))

FILE_MAP = {
    0: "khong4.csv",
    1: "dung2.csv",
    2: "sai4.csv",
    3: "co4.csv",
}

FILENAME = FILE_MAP[LABEL]
print(f">>> Ghi vào file: {FILENAME}")

# ===== SERIAL =====
ser = serial.Serial(PORT, BAUD, timeout=2)
time.sleep(2)  # chờ ESP32 boot

# ===== GHI FILE =====
# append mode → thu nhiều lần không mất data cũ
with open(FILENAME, "a") as f:

    current_sample = []
    recording      = False
    silent_mode    = (LABEL == 0)
    total_rows     = 0

    print(">>> Sẵn sàng. Ctrl+C để dừng.\n")

    while True:
        try:
            line = ser.readline().decode(errors='ignore').strip()
            if not line:
                continue

            print(line)

            # Bỏ qua header và comment
            if line == "START":
                current_sample = []
                recording = True
                continue

            if line == "END":
                recording = False
                if current_sample:
                    for row in current_sample:
                        f.write(row + "\n")
                    total_rows += len(current_sample)
                    f.flush()
                    print(f"✅ Saved {len(current_sample)} frames | Total: {total_rows}\n")
                current_sample = []
                continue

            # Chỉ xử lý dòng có dữ liệu (có dấu phẩy)
            if "," not in line:
                continue

            # ---- Silent mode: lưu thẳng, không cần nút ----
            if silent_mode:
                f.write(line + "\n")
                total_rows += 1
                if total_rows % 50 == 0:
                    f.flush()
                    print(f"  silent rows: {total_rows}")

            # ---- Normal mode: buffer giữa START/END ----
            elif recording:
                current_sample.append(line)

        except KeyboardInterrupt:
            print(f"\n✅ Dừng. Tổng rows đã lưu: {total_rows}")
            break
