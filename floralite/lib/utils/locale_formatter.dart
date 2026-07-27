import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for locale-based formatting of dates, times, currencies, and numbers.
class LocaleFormatter {
  /// Format a date according to the current locale.
  static String formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMd(locale.languageCode).format(date);
  }

  /// Format a date with time according to the current locale.
  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final locale = Localizations.localeOf(context);
    return DateFormat.yMd(locale.languageCode).add_Hm().format(dateTime);
  }

  /// Format a time according to the current locale.
  static String formatTime(BuildContext context, TimeOfDay time) {
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.Hm(locale.languageCode).format(dateTime);
  }

  /// Format a currency amount in INR according to the current locale.
  static String formatCurrency(BuildContext context, int paise) {
    final locale = Localizations.localeOf(context);
    final rupees = paise / 100.0;
    return NumberFormat.currency(
      locale: locale.languageCode == 'hi' ? 'hi_IN' : 
                locale.languageCode == 'gu' ? 'gu_IN' : 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(rupees);
  }

  /// Format a number according to the current locale.
  static String formatNumber(BuildContext context, num number) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.decimalPattern(locale.languageCode).format(number);
  }

  /// Format a number with decimal places according to the current locale.
  static String formatNumberWithDecimals(
    BuildContext context,
    num number, {
    int decimalDigits = 2,
  }) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.decimalPattern(locale.languageCode).format(number);
  }

  /// Format a percentage according to the current locale.
  static String formatPercentage(BuildContext context, num value) {
    final locale = Localizations.localeOf(context);
    return NumberFormat.percentPattern(locale.languageCode).format(value);
  }
}
