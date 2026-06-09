import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart';

// ImageUtils
class ImageUtils {
  static Image? convertCameraImageToImage(CameraImage cameraImage) {
    return switch (cameraImage.format.group) {
      ImageFormatGroup.yuv420 => _convertYUV420ToRGBImage(cameraImage),
      ImageFormatGroup.bgra8888 => _convertBGRA8888ToRGBImage(cameraImage),
      ImageFormatGroup.jpeg => _convertJPEGToImage(cameraImage),
      ImageFormatGroup.nv21 => _convertNV21ToRGBImage(cameraImage),
      ImageFormatGroup.unknown => null,
    };
  }

  static Image? _convertJPEGToImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    // first plane is responsible for holding all the image data
    final bytes = cameraImage.planes[0].bytes;

    // Create a new Image instance from the JPEG bytes
    final image = decodeImage(bytes);

    return image;
  }

  static Image _convertNV21ToRGBImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    final yuvBytes = cameraImage.planes[0].bytes;
    final vuBytes = cameraImage.planes[1].bytes;

    // Create a new Image instance
    final image = Image(
      width: cameraImage.width,
      height: cameraImage.height,
    );

    // Convert NV21 to RGB
    _convertNV21ToRGB(
      yuvBytes,
      vuBytes,
      cameraImage.width,
      cameraImage.height,
      image,
    );

    return image;
  }

  static void _convertNV21ToRGB(
    Uint8List yuvBytes,
    Uint8List vuBytes,
    int width,
    int height,
    Image image,
  ) {
    // NV21 format: V comes before U (hence "21", not "12")
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        final yValue = yuvBytes[yIndex];
        // NV21: V is at even indices, U is at odd indices
        final vValue = vuBytes[uvIndex * 2];
        final uValue = vuBytes[uvIndex * 2 + 1];

        // Convert YUV to RGB
        final r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        final g =
            (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                .round()
                .clamp(0, 255);
        final b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        // Set the RGB pixel values in the Image instance
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  // Converts a [CameraImage] in BGRA888 format to [imageLib.Image] in RGB format
  static Image _convertBGRA8888ToRGBImage(CameraImage cameraImage) {
    final firstPlane = cameraImage.planes[0];
    return Image.fromBytes(
      width: firstPlane.width!,
      height: firstPlane.height!,
      bytes: firstPlane.bytes.buffer,
      order: ChannelOrder.bgra,
    );
  }

  static Image _convertYUV420ToRGBImage(CameraImage cameraImage) {
    final imageWidth = cameraImage.width;
    final imageHeight = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int yPixelStride = yPlane.bytesPerPixel!;

    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel!;

    final image = Image(width: imageWidth, height: imageHeight);

    for (int h = 0; h < imageHeight; h++) {
      int uvh = (h / 2).floor();

      for (int w = 0; w < imageWidth; w++) {
        int uvw = (w / 2).floor();

        final yIndex = (h * yRowStride) + (w * yPixelStride);

        // Y plane should have positive values belonging to [0...255]
        final int y = yBuffer[yIndex];

        // U/V Values are subsampled i.e. each pixel in U/V chanel in a
        // YUV_420 image act as chroma value for 4 neighbouring pixels
        final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

        // U/V values ideally fall under [-0.5, 0.5] range. To fit them into
        // [0, 255] range they are scaled up and centered to 128.
        // Operation below brings U/V values to [-128, 127].
        final int u = uBuffer[uvIndex];
        final int v = vBuffer[uvIndex];

        // Compute RGB values per formula above.
        int r = (y + v * 1436 / 1024 - 179).round();
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
        int b = (y + u * 1814 / 1024 - 227).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        image.setPixelRgb(w, h, r, g, b);
      }
    }
    return image;
  }
}
