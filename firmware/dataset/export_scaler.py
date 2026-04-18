"""
Chạy script này SAU KHI train xong để export scaler params.
Output: scaler_params.json → copy vào assets/ của Flutter project
"""
import joblib, json

scaler = joblib.load("scaler.save")

params = {
    "mean": scaler.mean_.tolist(),
    "std":  scaler.scale_.tolist()
}

with open("scaler_params.json", "w") as f:
    json.dump(params, f)

print("✅ Exported scaler_params.json")
print("mean:", params["mean"])
print("std: ", params["std"])
