import 'ledger.dart';
import 'money.dart';

enum RepeatFrequency { daily, weekly, monthly, yearly }

enum ScheduleMode { confirm, automatic }

enum ScheduleState { active, paused, stopped }

enum OccurrenceState { posted, skipped, deleted }

String frequencyLabel(RepeatFrequency value) => switch (value) {
  RepeatFrequency.daily => 'Hari',
  RepeatFrequency.weekly => 'Minggu',
  RepeatFrequency.monthly => 'Bulan',
  RepeatFrequency.yearly => 'Tahun',
};
String scheduleStateLabel(ScheduleState value) => switch (value) {
  ScheduleState.active => 'Aktif',
  ScheduleState.paused => 'Dijeda',
  ScheduleState.stopped => 'Dihentikan',
};
const scheduleZones = <String, int>{
  'Asia/Jakarta': 7,
  'Asia/Makassar': 8,
  'Asia/Jayapura': 9,
};

/// Date-only arithmetic uses UTC as a calendar, never elapsed local DST hours.
/// [amount] is the TOTAL for installments, or the amount PER occurrence otherwise.
final class ScheduleRule {
  const ScheduleRule({
    required this.id,
    required this.name,
    required this.kind,
    required this.accountId,
    this.destinationId,
    required this.amount,
    required this.fee,
    required this.category,
    required this.note,
    required this.startDate,
    this.frequency = RepeatFrequency.monthly,
    this.interval = 1,
    this.endOfMonth = false,
    this.monthDay,
    this.endDate,
    this.count,
    this.installments = false,
    this.mode = ScheduleMode.confirm,
    this.zone = 'Asia/Jakarta',
    this.state = ScheduleState.active,
    required this.createdAt,
    this.time,
    this.weekdays = const [],
    this.receiverFee,
  });
  final String id, name, accountId, category, note, startDate, zone, createdAt;
  final String? destinationId, endDate;
  final TransactionKind kind;
  final Money amount, fee;
  final Money? receiverFee;
  Money get receivingFee => receiverFee ?? Money.zero;
  final RepeatFrequency frequency;
  final int interval;
  final int? monthDay;
  final int? count;
  final bool endOfMonth, installments;
  final ScheduleMode mode;
  final ScheduleState state;
  final String? time;
  final List<int> weekdays;

  String today(DateTime instant) =>
      localDate(instant.toUtc().add(Duration(hours: scheduleZones[zone]!)));

  /// Ordinal is zero based and permanently identifies this rule's occurrence.
  /// Calculate from the anchor, so Jan 31 -> Feb 28 -> Mar 31 does not drift.
  String? dateAt(int ordinal) {
    if (ordinal < 0 ||
        ordinal > 110000 ||
        (count != null && ordinal >= count!)) {
      return null;
    }
    final anchor = DateTime.parse('${startDate}T00:00:00Z');
    final step = ordinal * interval;
    late DateTime date;
    if (weekdays.isNotEmpty) {
      final days = [...weekdays]..sort();
      final firstWeek = days.where((d) => d >= anchor.weekday).toList();
      final startOfWeek = anchor.subtract(Duration(days: anchor.weekday - 1));
      if (ordinal < firstWeek.length) {
        date = startOfWeek.add(Duration(days: firstWeek[ordinal] - 1));
      } else {
        final n = ordinal - firstWeek.length;
        date = startOfWeek.add(
          Duration(
            days: (1 + n ~/ days.length) * 7 + days[n % days.length] - 1,
          ),
        );
      }
    } else {
      switch (frequency) {
        case RepeatFrequency.daily:
          if (step > DateTime.utc(2199, 12, 31).difference(anchor).inDays) {
            return null;
          }
          date = anchor.add(Duration(days: step));
        case RepeatFrequency.weekly:
          if (step * 7 > DateTime.utc(2199, 12, 31).difference(anchor).inDays) {
            return null;
          }
          date = anchor.add(Duration(days: step * 7));
        case RepeatFrequency.monthly:
          if (anchor.year * 12 + anchor.month - 1 + step >= 2200 * 12) {
            return null;
          }
          final first = DateTime.utc(anchor.year, anchor.month + step);
          final last = DateTime.utc(first.year, first.month + 1, 0).day;
          final day = monthDay ?? anchor.day;
          date = DateTime.utc(
            first.year,
            first.month,
            endOfMonth || day > last ? last : day,
          );
        case RepeatFrequency.yearly:
          final year = anchor.year + step;
          if (year > 2199) return null;
          final last = DateTime.utc(year, anchor.month + 1, 0).day;
          date = DateTime.utc(
            year,
            anchor.month,
            (monthDay ?? anchor.day) > last ? last : (monthDay ?? anchor.day),
          );
      }
    }
    if (date.year > 2199) return null;
    final value = localDate(date);
    if (value.compareTo(startDate) < 0) return null;
    if (endDate != null && value.compareTo(endDate!) > 0) return null;
    return value;
  }

  Money amountAt(int ordinal) {
    if (dateAt(ordinal) == null) {
      throw const FormatException('Urutan jadwal tidak valid.');
    }
    if (!installments) return amount;
    final parts = BigInt.from(count!);
    // All parts in sen; remainder goes to the last installment exactly.
    final base = amount.minor ~/ parts;
    return Money(
      base + (ordinal == count! - 1 ? amount.minor % parts : BigInt.zero),
    );
  }

  String get summary {
    if (weekdays.isNotEmpty) {
      const names = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      final days = [...weekdays]..sort();
      return 'Setiap ${days.map((d) => names[d - 1]).join(', ')}${time == null ? '' : ' · $time'}';
    }
    final unit = frequencyLabel(frequency).toLowerCase();
    final ending = frequency == RepeatFrequency.monthly
        ? (endOfMonth
              ? ' · akhir bulan'
              : ' · tanggal ${monthDay ?? DateTime.parse(startDate).day}')
        : '';
    return 'Setiap ${interval == 1 ? '' : '$interval '}$unit$ending${time == null ? '' : ' · $time'}';
  }

  ScheduleRule withState(ScheduleState value) =>
      ScheduleRule.fromJson({...toJson(), 'state': value.name});

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'account_id': accountId,
    'destination_id': destinationId,
    'amount_minor': amount.stored,
    'fee_minor': fee.stored,
    'category': category,
    'note': note,
    'start_date': startDate,
    'frequency': frequency.name,
    'interval': interval,
    'end_of_month': endOfMonth,
    'month_day': monthDay,
    'end_date': endDate,
    'count': count,
    'installments': installments,
    'mode': mode.name,
    'zone': zone,
    'state': state.name,
    'created_at': createdAt,
    if (time != null) 'time': time,
    if (weekdays.isNotEmpty) 'weekdays': weekdays,
    if (!receivingFee.isZero) 'receiver_fee_minor': receivingFee.stored,
  };

  factory ScheduleRule.fromJson(Map<String, Object?> json) {
    exactKeys(json, {
      'id',
      'name',
      'kind',
      'account_id',
      'destination_id',
      'amount_minor',
      'fee_minor',
      'category',
      'note',
      'start_date',
      'frequency',
      'interval',
      'end_of_month',
      'month_day',
      'end_date',
      'count',
      'installments',
      'mode',
      'zone',
      'state',
      'created_at',
      if (json.containsKey('time')) 'time',
      if (json.containsKey('weekdays')) 'weekdays',
      if (json.containsKey('receiver_fee_minor')) 'receiver_fee_minor',
    });
    T enumeration<T extends Enum>(String key, List<T> values) {
      final found = values.where((v) => v.name == json[key]);
      if (found.isEmpty) throw FormatException('$key tidak valid.');
      return found.first;
    }

    if (json['interval'] is! int ||
        (json['month_day'] != null && json['month_day'] is! int) ||
        (json['count'] != null && json['count'] is! int) ||
        json['end_of_month'] is! bool ||
        json['installments'] is! bool ||
        (json['destination_id'] != null && json['destination_id'] is! String) ||
        (json['end_date'] != null && json['end_date'] is! String)) {
      throw const FormatException('Struktur jadwal tidak valid.');
    }
    final rawDays = json['weekdays'];
    if (rawDays != null &&
        (rawDays is! List<Object?> || rawDays.any((v) => v is! int))) {
      throw const FormatException('Hari berulang tidak valid.');
    }
    final value = ScheduleRule(
      id: stringField(json, 'id'),
      name: stringField(json, 'name'),
      kind: enumeration('kind', TransactionKind.values),
      accountId: stringField(json, 'account_id'),
      destinationId: json['destination_id'] as String?,
      amount: Money.stored(stringField(json, 'amount_minor')),
      fee: Money.stored(stringField(json, 'fee_minor')),
      receiverFee: json.containsKey('receiver_fee_minor')
          ? Money.stored(stringField(json, 'receiver_fee_minor'))
          : null,
      category: stringField(json, 'category', empty: true),
      note: stringField(json, 'note', empty: true),
      startDate: stringField(json, 'start_date'),
      frequency: enumeration('frequency', RepeatFrequency.values),
      interval: json['interval']! as int,
      endOfMonth: json['end_of_month']! as bool,
      monthDay: json['month_day'] as int?,
      endDate: json['end_date'] as String?,
      count: json['count'] as int?,
      installments: json['installments']! as bool,
      mode: enumeration('mode', ScheduleMode.values),
      zone: stringField(json, 'zone'),
      state: enumeration('state', ScheduleState.values),
      createdAt: stringField(json, 'created_at'),
      time: json.containsKey('time') ? stringField(json, 'time') : null,
      weekdays: rawDays == null
          ? const []
          : List<int>.unmodifiable((rawDays as List<Object?>).cast<int>()),
    );
    value.validate();
    return value;
  }

  void validate() {
    validateDate(startDate);
    validateTime(time);
    if (endDate != null) validateDate(endDate!);
    if (weekdays.isNotEmpty &&
        (frequency != RepeatFrequency.daily ||
            interval != 1 ||
            weekdays.length > 7 ||
            weekdays.toSet().length != weekdays.length ||
            weekdays.any((v) => v < 1 || v > 7))) {
      throw const FormatException(
        'Pilih hari Senin sampai Minggu tanpa duplikat.',
      );
    }
    final year = DateTime.parse(startDate).year;
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        name.length > 80 ||
        !scheduleZones.containsKey(zone) ||
        interval < 1 ||
        interval > 999 ||
        year < 1900 ||
        year > 2199 ||
        (endDate != null &&
            (endDate!.compareTo(startDate) < 0 ||
                DateTime.parse(endDate!).year > 2199)) ||
        (count != null && (count! < 1 || count! > 1200)) ||
        (endOfMonth && frequency != RepeatFrequency.monthly) ||
        (monthDay != null &&
            ((frequency != RepeatFrequency.monthly &&
                    frequency != RepeatFrequency.yearly) ||
                monthDay! < 1 ||
                monthDay! > 31)) ||
        DateTime.tryParse(createdAt)?.isUtc != true) {
      throw const FormatException('Aturan jadwal tidak valid.');
    }
    if (installments &&
        (kind != TransactionKind.expense ||
            frequency != RepeatFrequency.monthly ||
            count == null ||
            count! < 2 ||
            endDate != null ||
            amount.minor < BigInt.from(count!))) {
      throw const FormatException(
        'Cicilan: pengeluaran bulanan, 2–1.200 bagian, minimal 1 sen tiap bagian.',
      );
    }
    LedgerTransaction(
      id: id,
      kind: kind,
      accountId: accountId,
      destinationId: destinationId,
      amount: amount,
      fee: fee,
      receiverFee: receiverFee,
      date: startDate,
      category: category,
      note: note,
      createdAt: createdAt,
    ).validate();
    if (dateAt(0) == null || (installments && dateAt(count! - 1) == null)) {
      throw const FormatException(
        'Rentang tanggal tidak mencakup jadwal yang dipilih (maksimal tahun 2199).',
      );
    }
  }
}

/// A tombstone survives ledger deletion. Never infer resolution from transactions.
final class ScheduleOccurrence {
  const ScheduleOccurrence({
    required this.scheduleId,
    required this.ordinal,
    required this.dueDate,
    required this.state,
    this.transactionId,
    required this.resolvedAt,
  });
  final String scheduleId, dueDate, resolvedAt;
  final int ordinal;
  final OccurrenceState state;
  final String? transactionId;
  String get key => '$scheduleId:$ordinal';
  Map<String, Object?> toJson() => {
    'schedule_id': scheduleId,
    'ordinal': ordinal,
    'due_date': dueDate,
    'state': state.name,
    'transaction_id': transactionId,
    'resolved_at': resolvedAt,
  };
  factory ScheduleOccurrence.fromJson(Map<String, Object?> json) {
    exactKeys(json, {
      'schedule_id',
      'ordinal',
      'due_date',
      'state',
      'transaction_id',
      'resolved_at',
    });
    final states = OccurrenceState.values.where((v) => v.name == json['state']);
    if (json['ordinal'] is! int ||
        states.isEmpty ||
        (json['transaction_id'] != null && json['transaction_id'] is! String)) {
      throw const FormatException('Kejadian jadwal tidak valid.');
    }
    final value = ScheduleOccurrence(
      scheduleId: stringField(json, 'schedule_id'),
      ordinal: json['ordinal']! as int,
      dueDate: stringField(json, 'due_date'),
      state: states.first,
      transactionId: json['transaction_id'] as String?,
      resolvedAt: stringField(json, 'resolved_at'),
    );
    validateDate(value.dueDate);
    if (value.ordinal < 0 ||
        value.ordinal > 110000 ||
        DateTime.tryParse(value.resolvedAt)?.isUtc != true ||
        (value.state == OccurrenceState.posted
            ? value.transactionId == null || value.transactionId!.trim().isEmpty
            : value.transactionId != null)) {
      throw const FormatException('Status kejadian jadwal tidak valid.');
    }
    return value;
  }
}
