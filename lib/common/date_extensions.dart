import 'package:intl/intl.dart';

String getFormattedDate(_date) {
    var inputFormat = DateFormat('yyyy-MM-dd HH:mm');
    var inputDate = inputFormat.parse(_date);
    var outputFormat = DateFormat('dd/MM/yyyy hh:mm');

    // Calculate time difference
    final timeDifference = DateTime.now().difference(inputDate);

    // Use formatTimeDifference for human-readable time if less than a week
    if (timeDifference.inDays < 7) {
        return formatTimeDifference(inputDate);
    } else {
        // If more than a week, use the default format
        return outputFormat.format(inputDate);
    }
}

String formatTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
        return 'a few seconds ago';
    } else if (difference.inMinutes < 10) {
        return 'a few minutes ago';
    } else if (difference.inHours < 1) {
        final minutes = difference.inMinutes;
        return "$minutes minute${minutes == 1 ? '' : 's'} ago";
    } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return "$hours hour${hours == 1 ? '' : 's'} ago";
    } else if (difference.inDays == 1) {
        return 'yesterday';
    } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return "$days day${days == 1 ? '' : 's'} ago";
    } else {
        final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
        return formatter.format(dateTime);
    }
}
