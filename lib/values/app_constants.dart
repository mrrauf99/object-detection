class AppConstants {
  const AppConstants._();

  static const instance = AppConstants._();

  static const String ssdMobileNetV1 = 'assets/model/ssd_mobilenet_v1.tflite';
  static const String ssdMobileNetV1LabelPath = 'assets/label/labels.txt';

  static const int ssdCompatibleImageHeight = 300;
  static const int ssdCompatibleImageWidth = 300;
}
