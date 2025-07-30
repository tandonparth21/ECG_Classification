# 🫀 ECG Image Classification & Visualization

This project uses an **ensemble of CNN models** (**VGG16**, **VGG19**, **ResNet50**) to classify ECG images into arrhythmia categories.  
It serves predictions via a **FastAPI** backend and visualizes results through an **R Shiny** dashboard.

---

## 📊 Dataset

This project uses the **ECG Arrhythmia Image Dataset**, an image version of the well-known heartbeat dataset:  
➡️ [Original dataset on Kaggle](https://www.kaggle.com/shayanfazeli/heartbeat)

**Context & Abstract:**
- Composed of two collections:
  - MIT-BIH Arrhythmia Dataset
  - PTB Diagnostic ECG Database
- Signals correspond to ECG heartbeats in both normal and pathological cases.
- Images are preprocessed and segmented into individual heartbeats.
- Used to explore deep learning and transfer learning for heartbeat classification.

**Details:**

| Dataset                        | Samples | Categories | Source                                       | Classes                                                                                 |
| ----------------------------- | ------: | ---------: | -------------------------------------------- | --------------------------------------------------------------------------------------: |
| MIT-BIH Arrhythmia Dataset    | 109,446 | 5          | Physionet                                   | `N` (0), `S` (1), `V` (2), `F` (3), `Q` (4)                                            |
| PTB Diagnostic ECG Database   | 14,552  | 2          | Physionet                                   | Normal vs Myocardial Infarction                                                        |

- Sampling Frequency: **125 Hz**
- Data split: 80% training, 20% testing

---

## 🚀 Tech Stack

- **Backend:** FastAPI, Uvicorn
- **Deep Learning:** TensorFlow (VGG16, VGG19, ResNet50)
- **Data & Image Processing:** Pillow, NumPy, python-multipart
- **Visualization:** R (Shiny, ggplot2, plotly, httr)

---

## ✅ Features

- Ensemble CNN improves accuracy by combining predictions.
- Upload ECG images to get instant model predictions.
- Visual dashboard for exploring and comparing predictions.

---

## 📦 Installation & Usage

### 1️⃣ Clone the repository
```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
