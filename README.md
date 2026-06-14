<div align="center">
  
# 🎯 LensAI: Flutter Object Detection

**A high-performance, real-time object detection application built with Flutter and TensorFlow Lite.**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![TensorFlow Lite](https://img.shields.io/badge/TensorFlow%20Lite-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)](https://www.tensorflow.org/lite)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](https://opensource.org/licenses/MIT)

</div>

---

## ✨ Overview

LensAI is a cutting-edge cross-platform application that leverages the power of **TensorFlow Lite** and the **SSD MobileNet V1 COCO** model to perform real-time, on-device object detection. Designed with performance and aesthetics in mind, the app processes camera frames instantaneously to draw accurate bounding boxes around recognized objects.

## 🚀 Key Features

- **Live Camera Detection**: Seamless, real-time object recognition using the device's camera.
- **Gallery Analysis**: Pick static images from your gallery and analyze them for multiple objects.
- **On-Device Machine Learning**: Zero network latency and complete privacy—all ML inference is done locally via `tflite_flutter`.
- **Advanced State Management**: Built with `MobX` for highly reactive, scalable, and boilerplate-free state management.
- **Dynamic Bounding Boxes**: Smooth, properly scaled bounding boxes mapping model tensor outputs directly to your device screen space.

## 📸 Previews

> *(Add your screenshots or GIFs here)*

## 🛠️ Architecture & Tech Stack

This project is built applying best practices in modular Flutter architecture:

* **Framework:** Flutter SDK
* **State Management:** MobX (`mobx`, `flutter_mobx`)
* **Machine Learning:** TensorFlow Lite (`tflite_flutter`)
* **Hardware Interfacing:** `camera`, `image_picker`
* **Image Processing:** `image` (Dart image manipulation library)
* **Assets Rendering:** `flutter_svg`

## ⚙️ Setup & Installation

Follow these steps to run the application locally on your machine:

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed (version 3.x+ recommended).
- A physical device or an emulator/simulator with camera support.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mrrauf99/object-detection.git
   cd object_detection
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

*Note: For the best real-time performance, it is highly recommended to run this application on a physical device in `Release` or `Profile` mode rather than an emulator.*
```bash
flutter run --release
```

## 🧠 ML Model Specifications

- **Model**: SSD MobileNet V1
- **Dataset**: COCO (Common Objects in Context)
- **Input Shape**: `[1, 300, 300, 3]`
- **Outputs**: 4 Tensors (Locations, Classes, Scores, Number of Detections)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/mrrauf99/object-detection/issues) if you want to contribute.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

---
<div align="center">
  <i>Built with ❤️ using Flutter & TensorFlow</i>
</div>
