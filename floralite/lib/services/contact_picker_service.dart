import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:permission_handler/permission_handler.dart';

class PickedContact {
  const PickedContact({
    required this.name,
    required this.mobile,
  });

  final String name;
  final String mobile;
}

class ContactPickerService {
  ContactPickerService._();

  static final FlutterNativeContactPicker _picker =
      FlutterNativeContactPicker();

  static Future<PickedContact?> pickContact(BuildContext context) async {
    final permissionGranted = await _ensurePermission(context);
    if (!permissionGranted) return null;
    if (!context.mounted) return null;

    final contact = await _selectContact(context);
    if (contact == null) return null;

    final mobileNumbers = <String>[
      if (contact.selectedPhoneNumber != null) contact.selectedPhoneNumber!,
      ...?contact.phoneNumbers,
    ]
        .map(normalizeMobile)
        .where((mobile) => mobile.isNotEmpty)
        .toSet()
        .toList();

    if (mobileNumbers.isEmpty) {
      if (context.mounted) {
        _showMessage(
          context,
          'Selected contact does not contain a mobile number.',
        );
      }
      return null;
    }

    final mobile = mobileNumbers.length == 1
        ? mobileNumbers.first
        : context.mounted
            ? await _chooseMobileNumber(
                context,
                contact.fullName?.trim() ?? '',
                mobileNumbers,
              )
            : null;
    if (mobile == null) return null;

    return PickedContact(
      name: contact.fullName?.trim() ?? '',
      mobile: mobile,
    );
  }

  static String normalizeMobile(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.startsWith('91') && digits.length > 10) {
      digits = digits.substring(2);
    }
    while (digits.startsWith('0') && digits.length > 10) {
      digits = digits.substring(1);
    }
    if (digits.length > 10) {
      digits = digits.substring(digits.length - 10);
    }

    return digits;
  }

  static Future<Contact?> _selectContact(BuildContext context) async {
    try {
      return await _picker.selectContact();
    } on PlatformException catch (error) {
      if (!context.mounted) return null;
      final message = error.code == 'no_contact'
          ? 'No contacts found.'
          : 'Unable to import contact. Please enter details manually.';
      _showMessage(context, message);
      return null;
    }
  }

  static Future<String?> _chooseMobileNumber(
    BuildContext context,
    String name,
    List<String> mobileNumbers,
  ) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(name.isEmpty ? 'Select Mobile Number' : name),
        children: [
          for (final mobile in mobileNumbers)
            ListTile(
              leading: const Icon(Icons.radio_button_unchecked),
              title: Text(mobile),
              onTap: () => Navigator.pop(dialogContext, mobile),
            ),
        ],
      ),
    );
  }

  static Future<bool> _ensurePermission(BuildContext context) async {
    final status = await Permission.contacts.status;
    if (status.isGranted || status.isLimited) return true;

    final result = await Permission.contacts.request();
    if (result.isGranted || result.isLimited) return true;

    if (context.mounted) {
      _showMessage(
        context,
        'Contacts permission is required to import phone numbers.',
      );
    }
    return false;
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
