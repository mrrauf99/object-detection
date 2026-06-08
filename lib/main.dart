import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:tensorflow_demo/services/tensorflow_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TensorflowService.ssdMobileNet.initialize();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MyApp());
}
