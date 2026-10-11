import 'package:intl/intl.dart';

class DateFormatUtil {
  static String date(DateTime dt) => DateFormat('EEE, MMM d, yyyy').format(dt);
  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);
  static String dateTime(DateTime dt) =>
      '${date(dt)} • ${time(dt)}';
}
