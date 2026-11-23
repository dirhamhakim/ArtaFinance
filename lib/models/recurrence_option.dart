import 'schedule.dart';

enum RecurrenceOption {
  daily('Setiap Hari', RepeatFrequency.daily, 1),
  weekdays('Setiap Hari Tertentu', RepeatFrequency.daily, 1),
  weekly('Setiap Minggu', RepeatFrequency.weekly, 1),
  fortnightly('Setiap 2 Minggu', RepeatFrequency.weekly, 2),
  fourWeekly('Setiap 4 Minggu', RepeatFrequency.weekly, 4),
  monthly('Setiap Bulan', RepeatFrequency.monthly, 1),
  monthEnd('Setiap Akhir Bulan', RepeatFrequency.monthly, 1),
  twoMonthly('Setiap 2 Bulan', RepeatFrequency.monthly, 2),
  quarterly('Setiap 3 Bulan', RepeatFrequency.monthly, 3),
  fourMonthly('Setiap 4 Bulan', RepeatFrequency.monthly, 4),
  halfYearly('Setiap 6 Bulan', RepeatFrequency.monthly, 6),
  yearly('Setiap Tahun', RepeatFrequency.yearly, 1);

  const RecurrenceOption(this.label, this.frequency, this.interval);
  final String label;
  final RepeatFrequency frequency;
  final int interval;
  static RecurrenceOption? match(
    RepeatFrequency frequency,
    int interval,
    bool monthEnd,
    List<int> weekdays,
  ) {
    if (weekdays.isNotEmpty) return RecurrenceOption.weekdays;
    if (monthEnd && frequency == RepeatFrequency.monthly && interval == 1) {
      return RecurrenceOption.monthEnd;
    }
    return values
        .where(
          (v) =>
              v != RecurrenceOption.weekdays &&
              v != RecurrenceOption.monthEnd &&
              v.frequency == frequency &&
              v.interval == interval,
        )
        .firstOrNull;
  }
}
