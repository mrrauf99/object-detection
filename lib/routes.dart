import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tensorflow_demo/screens/live_object_detection/live_object_detection_screen.dart';
import 'package:tensorflow_demo/screens/photo_analyzed/photo_analyze_screen.dart';
import 'package:tensorflow_demo/values/app_routes.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    Route<dynamic> getRoute({
      required Widget widget,
      bool fullscreenDialog = false,
    }) {
      return MaterialPageRoute<void>(
        builder: (context) => widget,
        settings: settings,
        fullscreenDialog: fullscreenDialog,
      );
    }

    switch (settings.name) {
      case AppRoutes.photoAnalyzedScreen:
        final imageBytes = settings.arguments as Uint8List?;

        return getRoute(
          widget: imageBytes?.isEmpty ?? true
              ? const Placeholder()
              : PhotoAnalyzedScreen(
                  imageBytes: imageBytes!,
                ),
        );
      case AppRoutes.cameraScreen:
        return getRoute(widget: const LiveObjectDetectionScreen());

      /// An invalid route. User shouldn't see this, it's for debugging purpose
      /// only.
      default:
        return getRoute(widget: const Placeholder());
    }
  }
}
