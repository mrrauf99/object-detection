import 'package:flutter/material.dart';

class SnackBarService {
  const SnackBarService._();

  static final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> get scaffoldMessengerKey =>
      _scaffoldMessengerKey;

  static void show(String message) {
    _scaffoldMessengerKey.currentState
      ?..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void remove() =>
      _scaffoldMessengerKey.currentState?.removeCurrentSnackBar();
}
