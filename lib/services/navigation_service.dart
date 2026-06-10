import 'package:flutter/material.dart';

class NavigationService {
  const NavigationService._(this._key);

  final GlobalKey<NavigatorState> _key;

  static final instance = NavigationService._(GlobalKey<NavigatorState>());

  GlobalKey<NavigatorState> get key => _key;

  Future<T?>? pushNamed<T>(String routeName, {Object? arguments}) {
    return _key.currentState?.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  Future<T?>? pushReplacementNamed<T extends Object?, TO extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    return _key.currentState?.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
    );
  }

  Future<T?> push<T extends Object?>(
    Widget screen, {
    String? name,
    Object? arguments,
  }) async {
    return _key.currentState?.push(
      MaterialPageRoute<T>(
        builder: (context) => screen,
        settings: RouteSettings(
          name: name ?? T.toString(),
          arguments: arguments,
        ),
      ),
    );
  }

  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget screen, {
    RouteSettings? settings,
    TO? result,
  }) async {
    return _key.currentState?.pushReplacement(
      MaterialPageRoute<T>(
        builder: (context) => screen,
        settings: settings ?? RouteSettings(name: T.toString()),
      ),
      result: result,
    );
  }

  String? getCurrentRoute() {
    String? name;
    _key.currentState?.popUntil((route) {
      name = route.settings.name;
      return true;
    });
    return name;
  }

  void pop<T extends Object?>([T? result]) => _key.currentState?.pop<T>(result);

  Future<bool>? maybePop<T extends Object?>([T? result]) =>
      _key.currentState?.maybePop<T>(result);

  void popUntil(RoutePredicate predicate) =>
      _key.currentState?.popUntil(predicate);

  Future<T?>? pushNamedAndRemoveUntil<T extends Object?>(
    String newRoute, {
    bool Function(Route<dynamic>)? predicate,
  }) {
    return _key.currentState
        ?.pushNamedAndRemoveUntil(newRoute, predicate ?? (_) => false);
  }

  Future<T?>? pushAndRemoveUntil<T extends Object?>(
    Widget screen, {
    bool Function(Route<dynamic> route)? predicate,
    String? name,
    Object? arguments,
  }) {
    return _key.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<T>(
        builder: (context) => screen,
        settings: RouteSettings(
          name: name ?? T.toString(),
          arguments: arguments,
        ),
      ),
      predicate ?? (_) => false,
    );
  }
}
