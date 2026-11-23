import 'decimal.dart';
import 'ledger.dart';
import 'money.dart';

final class InterestTier {
  InterestTier(this.from, this.percent);
  final Money from;
  final Decimal percent;
  Map<String, Object?> toJson() => {
    'from_minor': from.stored,
    'percent': percent.text,
  };
  factory InterestTier.fromJson(Map<String, Object?> j) {
    exactKeys(j, {'from_minor', 'percent'});
    return InterestTier(
      Money.stored(stringField(j, 'from_minor')),
      Decimal.parse(stringField(j, 'percent')),
    );
  }
}

final class InterestRule {
  InterestRule({
    required this.id,
    required this.accountId,
    required this.name,
    required this.start,
    required this.tiers,
    required this.taxPercent,
    this.end,
    this.progressive = false,
    this.previousClosing = true,
    this.monthly = false,
    this.daysBasis = 365,
    this.active = true,
    this.automatic = false,
  });
  final String id, accountId, name, start;
  final String? end;
  final List<InterestTier> tiers;
  final Decimal taxPercent;
  final bool progressive, previousClosing, monthly, active, automatic;
  final int daysBasis;
  Map<String, Object?> toJson() => {
    'id': id,
    'account_id': accountId,
    'name': name,
    'start': start,
    'end': end,
    'tiers': tiers.map((v) => v.toJson()).toList(),
    'tax_percent': taxPercent.text,
    'progressive': progressive,
    'previous_closing': previousClosing,
    'monthly': monthly,
    'days_basis': daysBasis,
    'active': active,
    'automatic': automatic,
  };
  factory InterestRule.fromJson(Map<String, Object?> j) {
    exactKeys(j, {
      'id',
      'account_id',
      'name',
      'start',
      'end',
      'tiers',
      'tax_percent',
      'progressive',
      'previous_closing',
      'monthly',
      'days_basis',
      'active',
      'automatic',
    });
    final r = InterestRule(
      id: stringField(j, 'id'),
      accountId: stringField(j, 'account_id'),
      name: stringField(j, 'name'),
      start: stringField(j, 'start'),
      end: j['end'] as String?,
      tiers: (j['tiers'] as List<Object?>)
          .map((v) => InterestTier.fromJson(objectMap(v)))
          .toList(),
      taxPercent: Decimal.parse(stringField(j, 'tax_percent')),
      progressive: boolField(j, 'progressive'),
      previousClosing: boolField(j, 'previous_closing'),
      monthly: boolField(j, 'monthly'),
      daysBasis: j['days_basis'] as int,
      active: boolField(j, 'active'),
      automatic: boolField(j, 'automatic'),
    );
    validateDate(r.start);
    if (r.end != null) validateDate(r.end!);
    if (r.name.length > 80 ||
        (r.end != null && r.end!.compareTo(r.start) < 0) ||
        !{360, 365, 366}.contains(r.daysBasis) ||
        r.taxPercent.negative ||
        r.taxPercent.compareTo(Decimal.parse('100')) > 0 ||
        r.tiers.isEmpty ||
        r.tiers.length > 20 ||
        !r.tiers.first.from.isZero) {
      throw const FormatException(
        'Aturan bunga tidak valid; tier pertama mulai saldo 0.',
      );
    }
    Money? last;
    for (final t in r.tiers) {
      if (t.from.isNegative ||
          (last != null && t.from.compareTo(last) <= 0) ||
          t.percent.negative ||
          t.percent.compareTo(Decimal.parse('1000')) > 0) {
        throw const FormatException(
          'Urutkan batas saldo tier secara naik dan isi tarif wajar.',
        );
      }
      last = t.from;
    }
    return r;
  }
}

final class InterestPosting {
  InterestPosting({
    required this.ruleId,
    required this.start,
    required this.end,
    required this.date,
    required this.gross,
    required this.tax,
    required this.idrRate,
    this.voided = false,
  });
  final String ruleId, start, end, date;
  final Money gross, tax;
  final Decimal idrRate;
  final bool voided;
  String get id => '$ruleId:$start:$end';
  Money get net => voided ? Money.zero : gross - tax;
  Map<String, Object?> toJson() => {
    'rule_id': ruleId,
    'start': start,
    'end': end,
    'date': date,
    'gross_minor': gross.stored,
    'tax_minor': tax.stored,
    'idr_rate': idrRate.text,
    'voided': voided,
  };
  factory InterestPosting.fromJson(Map<String, Object?> j) {
    exactKeys(j, {
      'rule_id',
      'start',
      'end',
      'date',
      'gross_minor',
      'tax_minor',
      'idr_rate',
      'voided',
    });
    final p = InterestPosting(
      ruleId: stringField(j, 'rule_id'),
      start: stringField(j, 'start'),
      end: stringField(j, 'end'),
      date: stringField(j, 'date'),
      gross: Money.stored(stringField(j, 'gross_minor')),
      tax: Money.stored(stringField(j, 'tax_minor')),
      idrRate: Decimal.parse(stringField(j, 'idr_rate')),
      voided: boolField(j, 'voided'),
    );
    validateDate(p.start);
    validateDate(p.end);
    validateDate(p.date);
    if (p.end.compareTo(p.start) < 0 ||
        p.gross.isNegative ||
        p.tax.isNegative ||
        p.tax.compareTo(p.gross) > 0 ||
        !p.idrRate.positive) {
      throw const FormatException('Pencatatan bunga tidak valid.');
    }
    return p;
  }
}
