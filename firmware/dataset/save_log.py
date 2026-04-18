import serial

ser = serial.Serial('COM20', 115200)  # sửa COM cho đúng

with open("data.csv", "w") as f:
    while True:
        line = ser.readline().decode(errors='ignore').strip()
        print(line)
        f.write(line + "\n")
