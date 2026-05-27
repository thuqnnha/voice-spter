import pandas as pd
import os

# ===== CONFIG =====
data_files = {
    "khong4.csv":  0,
    "dung2.csv":     1,
    "sai4.csv":     2,
}

NUMERIC_COLS = ['piezo_rms','piezo_peak','mic_rms','mic_zcr','mic_energy','ratio']

# ===== LOAD & CLEAN =====
def load_clean(file_path, label):
    df = pd.read_csv(file_path, header=0)   # ✅ đọc đúng header

    # Giữ đúng 7 cột
    df = df.iloc[:, :7]
    df.columns = NUMERIC_COLS + ['label']

    # Ép kiểu số, lọc dòng lỗi
    df[NUMERIC_COLS] = df[NUMERIC_COLS].apply(pd.to_numeric, errors='coerce')
    df = df.dropna()

    # Ép label đúng
    df['label'] = label

    return df

# ===== LOAD ALL =====
dfs = []

for file, label in data_files.items():
    if os.path.exists(file):
        df = load_clean(file, label)
        print(f"  {file}: {df.shape[0]} rows")
        dfs.append(df)
    else:
        print(f"⚠️  Missing: {file}")

if not dfs:
    raise RuntimeError("Không có file nào!")

# ===== CÂN BẰNG =====
min_len = min(len(d) for d in dfs)
print(f"\nMin rows/class: {min_len} → undersample về {min_len} mỗi class")

balanced = [d.sample(min_len, random_state=42) for d in dfs]
df = pd.concat(balanced, ignore_index=True)
df = df.sample(frac=1, random_state=42).reset_index(drop=True)

# ===== SAVE =====
df.to_csv("dataset_5.csv", index=False)
print("\n✅ Final dataset:", df.shape)
print(df['label'].value_counts().sort_index())
