import 'package:easy_localization/easy_localization.dart';

class DateFormatters {
  static String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String dateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// La hora en formato de 24 h: «18:30».
  static String time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// El día en palabras cuando está cerca («Hoy», «Mañana», «Ayer») y, si no, escrito en el idioma de
  /// [languageCode] («mié, 12 nov»; con el año si no es el actual). [now] solo se pasa en los tests.
  static String friendlyDay(DateTime day, String languageCode, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final daysAway = _calendarDay(day).difference(_calendarDay(clock)).inDays;
    return switch (daysAway) {
      0 => 'common.today'.tr(),
      1 => 'common.tomorrow'.tr(),
      -1 => 'common.yesterday'.tr(),
      _ => day.year == clock.year
          ? DateFormat.MMMEd(languageCode).format(day)
          : DateFormat.yMMMEd(languageCode).format(day),
    };
  }

  /// Un rango de fechas corto y localizado: «12 nov – 30 nov» (con el año si no es el actual).
  static String shortRange(
    DateTime start,
    DateTime end,
    String languageCode, {
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final format = start.year == clock.year && end.year == clock.year
        ? DateFormat.MMMd(languageCode)
        : DateFormat.yMMMd(languageCode);
    return '${format.format(start)} – ${format.format(end)}';
  }

  /// Medianoche de ese día, en UTC: así restar dos días da una cantidad exacta de días aunque cambie el horario de verano.
  static DateTime _calendarDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static String apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String apiDateTime(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}'
      'T${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
}
