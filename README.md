# 🫀 ECG Image Classification & Visualization

This project uses an **ensemble of CNN models** (**VGG16**, **VGG19**, **ResNet50**) to classify ECG images into arrhythmia categories.  
It serves predictions through a **FastAPI** backend and visualizes results in an **R Shiny** dashboard.

---

## 🏷 Classes & Their Meanings

The model predicts which of the following 5 classes an uploaded ECG image belongs to:

- **Class N (Normal):**  
  Represents normal sinus rhythm, where the heart beats regularly without anomalies.

- **Class S (Supraventricular ectopic beat):**  
  Premature beats originating above the heart’s ventricles, often benign but sometimes linked to arrhythmias.

- **Class V (Ventricular ectopic beat):**  
  Premature beats originating in the ventricles; may indicate structural heart issues.

- **Class F (Fusion beat):**  
  Result from fusion between normal and ectopic beats; relatively rare.

- **Class Q (Unknown beat):**  
  Unclassified or ambiguous beats, often noise or rare arrhythmias.

---

## 📊 Dataset

This project uses the **ECG Arrhythmia Image Dataset**, an image version of this dataset:  
➡️ [Original dataset on Kaggle](https://www.kaggle.com/shayanfazeli/heartbeat)

### Context & Abstract
- Combines two collections:
  - MIT-BIH Arrhythmia Dataset
  - PTB Diagnostic ECG Database
- Images represent ECG heartbeat segments labeled as normal or various arrhythmias.
- Enables deep learning and transfer learning on heartbeat classification tasks.

### Dataset Details:

| Dataset                        | Samples | Categories | Source                                       | Classes                                                                                 |
| ----------------------------- | ------: | ---------: | -------------------------------------------- | --------------------------------------------------------------------------------------: |
| MIT-BIH Arrhythmia Dataset    | 109,446 | 5          | Physionet                                   | `N` (0), `S` (1), `V` (2), `F` (3), `Q` (4)                                            |
| PTB Diagnostic ECG Database   | 14,552  | 2          | Physionet                                   | Normal vs Myocardial Infarction                                                        |

- Sampling Frequency: **125 Hz**
- Data split: **80% training, 20% testing**

---

## 🚀 Tech Stack

- **Backend:** FastAPI, Uvicorn
- **Deep Learning:** TensorFlow (VGG16, VGG19, ResNet50)
- **Image processing:** Pillow, NumPy, python-multipart
- **Visualization:** R (Shiny, ggplot2, plotly, httr)

---

## ✅ Features

- Ensemble CNN improves prediction accuracy.
- REST API built with FastAPI serves real-time predictions.
- R Shiny dashboard to upload ECG images and view predicted classes and plots interactively.

---

## 📦 Installation & Usage

### 1️⃣ Clone the repository
```bash
git clone https://github.com/your-username/your-repo-name.git
cd your-repo-name
