class WhatsAppPhoneUtils {
  const WhatsAppPhoneUtils._();

  static String? normalize(String? phone) {
    final raw = phone?.trim() ?? '';
    if (raw.isEmpty) return null;

    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    if (digits.length == 10) {
      return '+91$digits';
    }
    if (digits.length == 12 && digits.startsWith('91')) {
      return '+$digits';
    }
    if (raw.startsWith('+')) {
      return '+$digits';
    }
    return '+$digits';
  }

  static Uri? buildUri(String? phone, {String? message}) {
    final normalized = normalize(phone);
    if (normalized == null) return null;
    final uriPhone = normalized.substring(1);
    return Uri.https(
      'wa.me',
      '/$uriPhone',
      message == null || message.isEmpty ? null : {'text': message},
    );
  }

  static Uri? buildFallbackUri(String? phone, {String? message}) {
    final normalized = normalize(phone);
    if (normalized == null) return null;
    return Uri.https(
      'api.whatsapp.com',
      '/send',
      {
        'phone': normalized.substring(1),
        if (message != null && message.isNotEmpty) 'text': message,
      },
    );
  }
}
