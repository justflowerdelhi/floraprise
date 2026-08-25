import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstUsePermissionService {
  static const String _explainedPrefix = 'permission.explained.';

  static Future<bool> ensureExplainedOnce({
    required BuildContext context,
    required String flowKey,
    required String title,
    required String body,
  }) async {
    final shouldExplain = await _shouldExplain(flowKey);
    if (!context.mounted) {
      return false;
    }
    if (!shouldExplain) {
      return true;
    }

    final proceed = await _showExplanationDialog(
      context: context,
      title: title,
      body: body,
    );
    if (!proceed) {
      return false;
    }

    await _markExplained(flowKey);
    return true;
  }

  static Future<bool> ensurePermission({
    required BuildContext? context,
    required String flowKey,
    required Permission permission,
    required String title,
    required String body,
    required String permanentlyDeniedMessage,
  }) async {
    final status = await permission.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (context != null) {
      final shouldExplain = await _shouldExplain(flowKey);
      if (!context.mounted) {
        return false;
      }
      if (shouldExplain &&
          !status.isPermanentlyDenied &&
          !status.isRestricted) {
        final proceed = await _showExplanationDialog(
          context: context,
          title: title,
          body: body,
        );
        if (!proceed) {
          return false;
        }
        await _markExplained(flowKey);
      }
    }

    final requested = await permission.request();
    if (requested.isGranted || requested.isLimited) {
      return true;
    }

    if ((requested.isPermanentlyDenied || requested.isRestricted) &&
        context != null &&
        context.mounted) {
      _showPermissionDisabledMessage(
        context,
        permanentlyDeniedMessage,
      );
    }

    return false;
  }

  static Future<void> showPermanentlyDeniedMessage(
    BuildContext context,
    String message,
  ) async {
    if (!context.mounted) return;
    _showPermissionDisabledMessage(context, message);
  }

  static Future<bool> _showExplanationDialog({
    required BuildContext context,
    required String title,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  static void _showPermissionDisabledMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: const SnackBarAction(
            label: 'Open Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
  }

  static Future<bool> _shouldExplain(String flowKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_explainedPrefix$flowKey') ?? false);
  }

  static Future<void> _markExplained(String flowKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_explainedPrefix$flowKey', true);
  }
}
