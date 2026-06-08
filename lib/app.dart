import 'package:flutter/material.dart';
import 'package:tensorflow_demo/services/snackbar_service.dart';

import 'routes.dart';
import 'services/navigation_service.dart';
import 'values/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tensorflow Demo',
      navigatorKey: NavigationService.instance.key,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.cameraScreen,
      onGenerateRoute: Routes.generateRoute,
      scaffoldMessengerKey: SnackBarService.scaffoldMessengerKey,
    );
  }
}
