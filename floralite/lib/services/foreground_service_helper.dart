import 'dart:io';
import 'package:flutter/services.dart';

class ForegroundServiceHelper {
  static const MethodChannel _channel =
      MethodChannel('com.floraprise/location');

  static Future<void> startForegroundService(String deliveryId) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel
          .invokeMethod('startForegroundService', {'deliveryId': deliveryId});
    } catch (e) {
      // ignore: avoid_print
      print('Error starting foreground service: $e');
    }
  }

  static Future<void> stopForegroundService() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (e) {
      // ignore: avoid_print
      print('Error stopping foreground service: $e');
    }
  }

  static Future<void> updateNotification(String status) async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod('updateNotification', {'status': status});
    } catch (e) {
      // ignore: avoid_print
      print('Error updating notification: $e');
    }
  }
}
