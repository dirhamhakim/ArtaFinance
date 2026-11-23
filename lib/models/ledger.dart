import 'money.dart';
import 'schedule.dart';
import 'payment_card.dart';
import 'receipt_image.dart';
import 'decimal.dart';
import 'finance_extras.dart';
import 'investment.dart';

enum AccountKind { bank, cash, ewallet, exchange, liability, receivable, debit }

enum TransactionKind { income, expense, transfer }

String accountLabel(AccountKind kind) => switch (kind) {
  AccountKind.bank => 'Bank',
  AccountKind.cash => 'Tunai',
  AccountKind.debit => 'Kartu debit',
  AccountKind.ewallet => 'Dompet digital',
  AccountKind.exchange => 'Saldo exchange / sekuritas',
  AccountKind.liability => 'Utang / kartu kredit',
  AccountKind.receivable => 'Piutang / dana belum cair',
};
String transactionLabel(TransactionKind kind) => switch (kind) {
  TransactionKind.income => 'Pemasukan',
  TransactionKind.expense => 'Pengeluaran',
  TransactionKind.transfer => 'Transfer',
};

Map<String, Object?> objectMap(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('Objek tidak valid.');
  }
  return value;
}

String stringField(
  Map<String, Object?> json,
  String key, {
  bool empty = false,
}) {
  final value = json[key];
  if (value is! String || (!empty && value.trim().isEmpty)) {
    throw FormatException('Kolom $key tidak valid.');
  }
  return value;
}

void exactKeys(Map<String, Object?> json, Set<String> keys) {
  if (json.length != keys.length || !keys.containsAll(json.keys)) {
    throw const FormatException('Struktur data tidak didukung.');
  }
}

bool boolField(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) throw FormatException('Kolom $key harus boolean.');
  return value;
}

String localDate(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
void validateDate(String text) {
  final parsed = DateTime.tryParse(text);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
      parsed == null ||
      localDate(parsed) != text) {
    throw const FormatException('Tanggal tidak valid.');
  }
}

void validateTime(String? value) {
  if (value != null &&
      !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
    throw const FormatException('Jam harus berformat 24 jam HH:mm.');
  }
}

String localTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

final class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.opening,
    required this.createdAt,
    this.currency = 'IDR',
    this.providerId,
  });
  final String id, name, createdAt, currency;
  final String? providerId;
  final AccountKind kind;
  final Money opening;
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    if (providerId != null) 'provider_id': providerId,
    'currency': currency,
    'opening_minor': opening.stored,
    'created_at': createdAt,
  };
  factory Account.fromJson(Map<String, Object?> json) {
    exactKeys(json, {
      'id',
      'name',
      'kind',
      'currency',
      if (json.containsKey('provider_id')) 'provider_id',
      'opening_minor',
      'created_at',
    });
    if (!currencies.contains(json['currency'])) {
      throw const FormatException('Mata uang belum didukung.');
    }
    final created = stringField(json, 'created_at');
    if (DateTime.tryParse(created)?.isUtc != true) {
      throw const FormatException('Waktu pembuatan harus UTC.');
    }
    final kindName = stringField(json, 'kind');
    final kinds = AccountKind.values.where((v) => v.name == kindName);
    if (kinds.isEmpty) throw const FormatException('Jenis aset tidak valid.');
    final name = stringField(json, 'name');
    if (name.length > 80) {
      throw const FormatException('Nama aset maksimal 80 karakter.');
    }
    return Account(
      id: stringField(json, 'id'),
      name: name,
      kind: kinds.first,
      opening: Money.stored(stringField(json, 'opening_minor')),
      createdAt: created,
      currency: stringField(json, 'currency'),
      providerId: json.containsKey('provider_id')
          ? stringField(json, 'provider_id')
          : null,
    );
  }
}

final class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.kind,
    required this.accountId,
    required this.destinationId,
    required this.amount,
    required this.fee,
    required this.date,
    required this.category,
    required this.note,
    required this.createdAt,
    this.time,
    this.zone = 'Asia/Jakarta',
    this.cardId,
    this.images = const [],
    this.destinationAmount,
    this.idrRate,
    this.receiverFee,
    this.receiverFeeRate,
  });
  final String id, accountId, date, category, note, createdAt;
  final String? destinationId;
  final TransactionKind kind;
  final Money amount, fee;
  final String? time, cardId;
  final String zone;
  final List<ReceiptImage> images;
  final Money? destinationAmount;
  final Decimal? idrRate, receiverFeeRate;
  final Money? receiverFee;
  Money get receivingFee => receiverFee ?? Money.zero;
  Money get expenseIdr =>
      (idrRate ?? Decimal.one).timesMoney(
        kind == TransactionKind.expense
            ? amount
            : kind == TransactionKind.transfer
            ? fee
            : Money.zero,
      ) +
      (receiverFeeRate ?? idrRate ?? Decimal.one).timesMoney(receivingFee);
  Money deltaFor(String id) {
    if (kind == TransactionKind.transfer) {
      if (id == accountId) return -(amount + fee);
      if (id == destinationId) {
        return (destinationAmount ?? amount) - receivingFee;
      }
      return Money.zero;
    }
    if (id != accountId) return Money.zero;
    return kind == TransactionKind.income ? amount : -amount;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'account_id': accountId,
    'destination_id': destinationId,
    'amount_minor': amount.stored,
    'fee_minor': fee.stored,
    'date': date,
    'category': category,
    'note': note,
    'created_at': createdAt,
    if (time != null) 'time': time,
    if (time != null || zone != 'Asia/Jakarta') 'zone': zone,
    if (cardId != null) 'card_id': cardId,
    if (images.isNotEmpty) 'images': images.map((v) => v.toJson()).toList(),
    if (destinationAmount != null)
      'destination_minor': destinationAmount!.stored,
    if (idrRate != null) 'idr_rate': idrRate!.text,
    if (!receivingFee.isZero) 'receiver_fee_minor': receivingFee.stored,
    if (receiverFeeRate != null) 'receiver_fee_rate': receiverFeeRate!.text,
  };
  factory LedgerTransaction.fromJson(Map<String, Object?> json) {
    exactKeys(json, {
      'id',
      'kind',
      'account_id',
      'destination_id',
      'amount_minor',
      'fee_minor',
      'date',
      'category',
      'note',
      'created_at',
      if (json.containsKey('time')) 'time',
      if (json.containsKey('zone')) 'zone',
      if (json.containsKey('card_id')) 'card_id',
      if (json.containsKey('images')) 'images',
      if (json.containsKey('destination_minor')) 'destination_minor',
      if (json.containsKey('idr_rate')) 'idr_rate',
      if (json.containsKey('receiver_fee_minor')) 'receiver_fee_minor',
      if (json.containsKey('receiver_fee_rate')) 'receiver_fee_rate',
    });
    final name = stringField(json, 'kind');
    final kinds = TransactionKind.values.where((v) => v.name == name);
    if (kinds.isEmpty) {
      throw const FormatException('Jenis transaksi tidak valid.');
    }
    final destination = json['destination_id'];
    if (destination != null &&
        (destination is! String || destination.isEmpty)) {
      throw const FormatException('Aset tujuan tidak valid.');
    }
    final date = stringField(json, 'date');
    validateDate(date);
    final created = stringField(json, 'created_at');
    if (DateTime.tryParse(created)?.isUtc != true) {
      throw const FormatException('Waktu pembuatan harus UTC.');
    }
    final result = LedgerTransaction(
      id: stringField(json, 'id'),
      kind: kinds.first,
      accountId: stringField(json, 'account_id'),
      destinationId: destination as String?,
      amount: Money.stored(stringField(json, 'amount_minor')),
      fee: Money.stored(stringField(json, 'fee_minor')),
      date: date,
      category: stringField(json, 'category', empty: true),
      note: stringField(json, 'note', empty: true),
      createdAt: created,
      time: json.containsKey('time') ? stringField(json, 'time') : null,
      zone: json.containsKey('zone')
          ? stringField(json, 'zone')
          : 'Asia/Jakarta',
      cardId: json.containsKey('card_id') ? stringField(json, 'card_id') : null,
      images: json.containsKey('images')
          ? _readImages(json['images'])
          : const [],
      destinationAmount: json.containsKey('destination_minor')
          ? Money.stored(stringField(json, 'destination_minor'))
          : null,
      receiverFee: json.containsKey('receiver_fee_minor')
          ? Money.stored(stringField(json, 'receiver_fee_minor'))
          : null,
      receiverFeeRate: json.containsKey('receiver_fee_rate')
          ? Decimal.parse(stringField(json, 'receiver_fee_rate'))
          : null,
      idrRate: json.containsKey('idr_rate')
          ? Decimal.parse(stringField(json, 'idr_rate'))
          : null,
    );
    result.validate();
    return result;
  }
  void validate() {
    if (receivingFee.isNegative ||
        (receiverFeeRate != null && !receiverFeeRate!.positive) ||
        (kind != TransactionKind.transfer &&
            (!receivingFee.isZero || receiverFeeRate != null)) ||
        (kind == TransactionKind.transfer &&
            receivingFee.compareTo(destinationAmount ?? amount) >= 0)) {
      throw const FormatException(
        'Biaya penerima harus minimal 0 dan kurang dari nominal tujuan.',
      );
    }
    if ((destinationAmount != null &&
            (kind != TransactionKind.transfer ||
                !destinationAmount!.isPositive)) ||
        (idrRate != null && !idrRate!.positive)) {
      throw const FormatException('Nominal tujuan atau kurs tidak valid.');
    }
    validateDate(date);
    validateTime(time);
    if (!scheduleZones.containsKey(zone) ||
        images.length > ReceiptImage.maxCount) {
      throw const FormatException(
        'Zona waktu atau jumlah lampiran tidak valid.',
      );
    }
    final imageIds = <String>{};
    for (final image in images) {
      ReceiptImage.fromJson(image.toJson());
      if (!imageIds.add(image.id)) {
        throw const FormatException('ID lampiran duplikat.');
      }
    }
    if (!amount.isPositive || fee.isNegative) {
      throw const FormatException(
        'Nominal harus positif; biaya tidak boleh minus.',
      );
    }
    if (kind == TransactionKind.transfer) {
      if (destinationId == null || destinationId == accountId) {
        throw const FormatException('Pilih dua aset yang berbeda.');
      }
    } else if (destinationId != null ||
        !fee.isZero ||
        category.trim().isEmpty) {
      throw const FormatException(
        'Kategori wajib diisi; biaya hanya untuk transfer.',
      );
    }
    if (category.length > 80 || note.length > 1000) {
      throw const FormatException('Kategori atau catatan terlalu panjang.');
    }
  }
}

List<ReceiptImage> _readImages(Object? value) {
  if (value is! List<Object?> || value.length > ReceiptImage.maxCount) {
    throw const FormatException('Maksimal tiga lampiran per transaksi.');
  }
  return List.unmodifiable(
    value.map((v) => ReceiptImage.fromJson(objectMap(v))),
  );
}

final class LedgerSnapshot {
  LedgerSnapshot({
    required List<Account> accounts,
    required List<LedgerTransaction> transactions,
    List<ScheduleRule> schedules = const [],
    List<ScheduleOccurrence> occurrences = const [],
    this.theme = 'dark',
    List<PaymentCard> cards = const [],
    this.extras = const FinanceExtras(),
  }) : accounts = List.unmodifiable(accounts),
       transactions = List.unmodifiable(transactions),
       schedules = List.unmodifiable(schedules),
       occurrences = List.unmodifiable(occurrences),
       cards = List.unmodifiable(cards);
  factory LedgerSnapshot.empty() =>
      LedgerSnapshot(accounts: [], transactions: []);
  final List<Account> accounts;
  final List<LedgerTransaction> transactions;
  final List<ScheduleRule> schedules;
  final List<ScheduleOccurrence> occurrences;
  final String theme;
  final List<PaymentCard> cards;
  final FinanceExtras extras;
  LedgerSnapshot withExtras(FinanceExtras value) => LedgerSnapshot(
    accounts: accounts,
    transactions: transactions,
    schedules: schedules,
    occurrences: occurrences,
    theme: theme,
    cards: cards,
    extras: value,
  );
  Money balance(String accountId) => balanceAt(accountId);
  Money balanceAt(String accountId, {String? through}) {
    var value = transactions
        .where((t) => through == null || t.date.compareTo(through) <= 0)
        .fold(
          accounts.firstWhere((a) => a.id == accountId).opening,
          (balance, tx) => balance + tx.deltaFor(accountId),
        );
    for (final e in extras.events.where(
      (e) => through == null || e.date.compareTo(through) <= 0,
    )) {
      value = value + e.cashDelta(accountId);
    }
    final rules = {for (final r in extras.interestRules) r.id: r};
    for (final p in extras.interestPostings.where(
      (p) =>
          rules[p.ruleId]?.accountId == accountId &&
          (through == null || p.date.compareTo(through) <= 0),
    )) {
      value = value + p.net;
    }
    return value;
  }

  int get missingFxCount =>
      accounts.where((a) => extras.rate(a.currency) == null).length;
  Money get total => accounts.fold(
    Money.zero,
    (sum, a) =>
        sum +
        (extras.rate(a.currency)?.timesMoney(balance(a.id)) ?? Money.zero),
  );
  Money get investmentValue => extras.holdings
      .where((h) => h.quantity.positive)
      .fold(
        Money.zero,
        (sum, h) => sum + (extras.holdingValue(h) ?? Money.zero),
      );
  int get unpricedHoldings => extras.holdings
      .where((h) => h.quantity.positive && extras.holdingValue(h) == null)
      .length;
  Money get netWorth => total + investmentValue;
  Money remainingForSchedule(ScheduleRule rule) =>
      rule.amount -
      occurrences
          .where((o) => o.scheduleId == rule.id)
          .fold(Money.zero, (sum, o) => sum + rule.amountAt(o.ordinal));
  Money actualExpenseForSchedule(String id) {
    final transactionIds = occurrences
        .where((o) => o.scheduleId == id && o.state == OccurrenceState.posted)
        .map((o) => o.transactionId)
        .toSet();
    return transactions
        .where((t) => transactionIds.contains(t.id))
        .fold(
          Money.zero,
          (sum, t) =>
              sum +
              switch (t.kind) {
                TransactionKind.expense => t.amount,
                TransactionKind.transfer => t.fee + t.receivingFee,
                TransactionKind.income => Money.zero,
              },
        );
  }

  Money incomeForMonth(String month) =>
      transactions
          .where(
            (t) => t.date.startsWith(month) && t.kind == TransactionKind.income,
          )
          .fold(
            Money.zero,
            (sum, t) => sum + (t.idrRate ?? Decimal.one).timesMoney(t.amount),
          ) +
      extras.events
          .where(
            (e) =>
                e.date.startsWith(month) && e.kind == InvestmentKind.dividend,
          )
          .fold(Money.zero, (sum, e) => sum + e.idrRate.timesMoney(e.gross)) +
      extras.interestPostings
          .where((p) => !p.voided && p.date.startsWith(month))
          .fold(Money.zero, (sum, p) => sum + p.idrRate.timesMoney(p.gross));
  Money expenseForMonth(String month) =>
      transactions
          .where((t) => t.date.startsWith(month))
          .fold(Money.zero, (sum, t) => sum + t.expenseIdr) +
      extras.events
          .where(
            (e) => e.date.startsWith(month) && e.kind != InvestmentKind.opening,
          )
          .fold(Money.zero, (sum, e) => sum + e.idrRate.timesMoney(e.fee)) +
      extras.interestPostings
          .where((p) => !p.voided && p.date.startsWith(month))
          .fold(Money.zero, (sum, p) => sum + p.idrRate.timesMoney(p.tax));
  void validate() {
    if (!{'dark', 'light', 'system'}.contains(theme)) {
      throw const FormatException('Tema tidak valid.');
    }
    final ids = <String>{};
    for (final account in accounts) {
      Account.fromJson(account.toJson());
      if (!ids.add(account.id)) {
        throw const FormatException('ID aset duplikat.');
      }
    }
    final transactionIds = <String>{};
    extras.validate(accounts);
    final cardIds = <String>{};
    for (final card in cards) {
      PaymentCard.fromJson(card.toJson());
      if (!cardIds.add(card.id) ||
          !accounts.any(
            (a) => a.id == card.accountId && a.kind == AccountKind.bank,
          )) {
        throw const FormatException(
          'Kartu debit harus terhubung ke aset bank yang ada.',
        );
      }
    }
    for (final tx in transactions) {
      LedgerTransaction.fromJson(tx.toJson());
      if (!transactionIds.add(tx.id) ||
          (tx.cardId != null && !cardIds.contains(tx.cardId)) ||
          !ids.contains(tx.accountId) ||
          (tx.destinationId != null && !ids.contains(tx.destinationId))) {
        throw const FormatException(
          'Referensi transaksi tidak valid atau ID duplikat.',
        );
      }
      final a = accounts.firstWhere((a) => a.id == tx.accountId);
      if ((a.currency != 'IDR' && tx.idrRate == null) ||
          (a.currency == 'IDR' &&
              tx.idrRate != null &&
              tx.idrRate != Decimal.one)) {
        throw const FormatException(
          'Transaksi memerlukan kurs historis IDR yang sesuai.',
        );
      }
      if (tx.destinationId != null) {
        final b = accounts.firstWhere((a) => a.id == tx.destinationId);
        if ((!tx.receivingFee.isZero &&
                a.currency != b.currency &&
                tx.receiverFeeRate == null) ||
            (b.currency == 'IDR' &&
                tx.receiverFeeRate != null &&
                tx.receiverFeeRate != Decimal.one) ||
            (a.currency == b.currency &&
                tx.receiverFeeRate != null &&
                tx.idrRate != null &&
                tx.receiverFeeRate != tx.idrRate)) {
          throw const FormatException(
            'Biaya penerima memerlukan kurs historis mata uang tujuan yang sesuai.',
          );
        }
        if (a.currency != b.currency && tx.destinationAmount == null) {
          throw const FormatException(
            'Transfer lintas mata uang memerlukan nominal tujuan.',
          );
        }
        if (a.currency == b.currency &&
            tx.destinationAmount != null &&
            tx.destinationAmount != tx.amount) {
          throw const FormatException(
            'Transfer mata uang sama harus mempunyai nominal tujuan yang sama.',
          );
        }
      }
    }
    final rules = <String, ScheduleRule>{};
    for (final rule in schedules) {
      ScheduleRule.fromJson(rule.toJson());
      if (rules.containsKey(rule.id) ||
          !ids.contains(rule.accountId) ||
          (rule.destinationId != null && !ids.contains(rule.destinationId))) {
        throw const FormatException(
          'Referensi jadwal tidak valid atau ID duplikat.',
        );
      }
      rules[rule.id] = rule;
      if (rule.destinationId != null &&
          accounts.firstWhere((a) => a.id == rule.accountId).currency !=
              accounts.firstWhere((a) => a.id == rule.destinationId).currency) {
        throw const FormatException(
          'Jadwal transfer memakai dua aset bermata uang sama.',
        );
      }
    }
    final keys = <String>{};
    final linked = <String>{};
    for (final occurrence in occurrences) {
      ScheduleOccurrence.fromJson(occurrence.toJson());
      final rule = rules[occurrence.scheduleId];
      if (!keys.add(occurrence.key) ||
          rule == null ||
          rule.dateAt(occurrence.ordinal) != occurrence.dueDate ||
          (occurrence.transactionId != null &&
              (!transactionIds.contains(occurrence.transactionId) ||
                  !linked.add(occurrence.transactionId!)))) {
        throw const FormatException(
          'Riwayat kejadian tidak valid atau duplikat.',
        );
      }
    }
  }
}
