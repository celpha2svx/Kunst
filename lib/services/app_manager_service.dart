import 'package:flutter/services.dart';

class AppManagerService {
  static const MethodChannel _channel = MethodChannel('kunst_launcher/platform');

  Future<bool> hideApp(String packageName) async {
    return (await _channel.invokeMethod<bool>('hideApp', {'package': packageName})) ?? false;
  }

  Future<bool> showApp(String packageName) async {
    return (await _channel.invokeMethod<bool>('showApp', {'package': packageName})) ?? false;
  }

  Future<bool> isAppHidden(String packageName) async {
    return (await _channel.invokeMethod<bool>('isAppHidden', {'package': packageName})) ?? false;
  }

  Future<bool> killApp(String packageName) async {
    return (await _channel.invokeMethod<bool>('killApp', {'package': packageName})) ?? false;
  }

  Future<bool> bulkHideApps(List<String> packageNames) async {
    return (await _channel.invokeMethod<bool>('bulkHideApps', {'packages': packageNames})) ?? false;
  }

  Future<bool> bulkShowApps(List<String> packageNames) async {
    return (await _channel.invokeMethod<bool>('bulkShowApps', {'packages': packageNames})) ?? false;
  }
}
