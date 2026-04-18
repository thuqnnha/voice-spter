import pandas as pd

# ===== Hàm load & clean từng file =====
def load_clean(file_path, label):
    df = pd.read_csv(file_path, header=None)

    # chỉ lấy 7 cột đầu
    df = df.iloc[:, :7]

    # đặt tên cột
    df.columns = [
        'piezo_rms',
        'piezo_peak',
        'mic_rms',
        'mic_zcr',
        'mic_energy',
        'ratio',
        'label'
    ]

    # gán label đúng (ghi đè nếu file sai)
    df['label'] = label

    # xóa dòng lỗi
    df = df.dropna()

    return df


# ===== Load từng class =====
df_yes = load_clean("yes.csv", 1)
df_no = load_clean("no.csv", 2)
df_silent = load_clean("silent.csv", 0)

print("yes:", df_yes.shape)
print("no:", df_no.shape)
print("silent:", df_silent.shape)

# ===== CÂN BẰNG DATA =====
min_len = min(len(df_yes), len(df_no), len(df_silent))

df_yes = df_yes.sample(min_len, random_state=42)
df_no = df_no.sample(min_len, random_state=42)
df_silent = df_silent.sample(min_len, random_state=42)

# ===== GỘP =====
df = pd.concat([df_yes, df_no, df_silent], ignore_index=True)

# shuffle
df = df.sample(frac=1, random_state=42)

# ===== Lưu =====
df.to_csv("dataset_clean.csv", index=False)

print("✅ Dataset sạch:", df.shape)
print(df.head())
