import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_example/mixin/app_locale.dart';
import 'package:flutter_localization/flutter_localization.dart';

String getFormattedDate(String dateString, BuildContext context) {
    var inputFormat = DateFormat('yyyy-MM-dd HH:mm');
    var inputDate = inputFormat.parse(dateString);

    // Calculate time difference
    final timeDifference = DateTime.now().difference(inputDate);

    // Use formatTimeDifference for human-readable time if less than a week
    if (timeDifference.inDays < 7) {
        return formatTimeDifference(inputDate, context);
    } else {
        // If more than a week, use the locale-aware format
        final locale = Localizations.localeOf(context).toString();
        var outputFormat = DateFormat('dd/MM/yyyy HH:mm', locale); // Using HH for 24-hour
        return outputFormat.format(inputDate);
    }
}

String formatTimeDifference(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) { // This is the "difference.inMinutes < 1" case
        return AppLocale.timeFewSecondsAgo.getString(context);
    } else if (difference.inMinutes < 60) { // Handles 1 to 59 minutes
        if (difference.inMinutes == 1) {
            return AppLocale.timeMinuteAgo.getString(context).replaceAll('{minutes}', '1');
        } else if (difference.inMinutes < 5) {
            return AppLocale.timeFewMinutesAgo.getString(context);
        } else { // 5 to 59 minutes
            return AppLocale.timeMinutesAgo.getString(context).replaceAll('{minutes}', difference.inMinutes.toString());
        }
    } else if (difference.inHours < 24) { // Less than a day
        final hours = difference.inHours;
        if (hours == 1) {
            return AppLocale.timeHourAgo.getString(context).replaceAll('{hours}', '1');
        } else {
            return AppLocale.timeHoursAgo.getString(context).replaceAll('{hours}', hours.toString());
        }
    } else if (difference.inDays == 1) {
        return AppLocale.timeYesterday.getString(context);
    } else if (difference.inDays < 7) { // 2 to 6 days
        final days = difference.inDays;
        return AppLocale.timeDaysAgo.getString(context).replaceAll('{days}', days.toString());
    } else {
        // This case should ideally not be reached if getFormattedDate calls this only for difference < 7 days.
        // Fallback to a standard format if it is somehow reached.
        final locale = Localizations.localeOf(context).toString();
        return DateFormat('yyyy-MM-dd HH:mm', locale).format(dateTime);
    }
}
