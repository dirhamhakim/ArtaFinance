import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/ledger.dart';
import '../models/money.dart';
import '../models/schedule.dart';
import '../models/payment_card.dart';
import '../services/schedule_engine.dart';
import '../models/finance_extras.dart';
import '../models/investment.dart';
import '../models/interest.dart';
import '../services/interest_engine.dart';
import '../models/staking.dart';
import '../models/transaction_category.dart';
import '../services/transaction_category_service.dart';

final class FinanceRepository {
  FinanceRepository(this.database);
  final AppDatabase database;

  Future<LedgerSnapshot> load() => database.transaction(() async {
    final accounts = await database
        .customSelect('SELECT body FROM accounts ORDER BY rowid')
        .get();
    final transactions = await database
        .customSelect(
          r"SELECT body FROM ledger_transactions ORDER BY date DESC, json_extract(body, '$.time') DESC, rowid DESC",
        )
        .get();
    final preferences = await database
        .customSelect("SELECT value FROM preferences WHERE key = 'theme'")
        .get();
    final schedules = await database
        .customSelect('SELECT body FROM schedules ORDER BY rowid')
        .get();
    final occurrences = await database
        .customSelect(
          'SELECT body FROM schedule_occurrences ORDER BY schedule_id, ordinal',
        )
        .get();
    final result = LedgerSnapshot(
      extras: await _loadExtras(),
      cards:
          (await database
                  .customSelect('SELECT body FROM payment_cards ORDER BY rowid')
                  .get())
              .map(
                (r) => PaymentCard.fromJson(
                  objectMap(jsonDecode(r.read<String>('body'))),
                ),
              )
              .toList(),
      accounts: accounts
          .map(
            (row) => Account.fromJson(
              objectMap(jsonDecode(row.read<String>('body'))),
            ),
          )
          .toList(),
      transactions: transactions
          .map(
            (row) => LedgerTransaction.fromJson(
              objectMap(jsonDecode(row.read<String>('body'))),
            ),
          )
          .toList(),
      theme: preferences.isEmpty
          ? 'dark'
          : preferences.first.read<String>('value'),
      schedules: schedules
          .map(
            (r) => ScheduleRule.fromJson(
              objectMap(jsonDecode(r.read<String>('body'))),
            ),
          )
          .toList(),
      occurrences: occurrences
          .map(
            (r) => ScheduleOccurrence.fromJson(
              objectMap(jsonDecode(r.read<String>('body'))),
            ),
          )
          .toList(),
    );
    result.validate();
    return result;
  });

  Future<FinanceExtras> _loadExtras() async {
    final rows = await database
        .customSelect("SELECT body FROM finance_extras WHERE id='main'")
        .get();
    return rows.isEmpty
        ? const FinanceExtras()
        : FinanceExtras.fromJson(
            objectMap(jsonDecode(rows.single.read<String>('body'))),
          );
  }

  Future<void> _writeExtras(FinanceExtras value) => database.customStatement(
    "INSERT OR REPLACE INTO finance_extras(id,body) VALUES ('main',?)",
    [jsonEncode(value.toJson())],
  );
  Future<void> updateExtras(FinanceExtras Function(FinanceExtras) update) =>
      database.transaction(() async {
        final data = await load();
        final next = update(data.extras);
        data.withExtras(next).validate();
        await _writeExtras(next);
      });

  Future<void> saveCategory(TransactionCategory value, {bool edit = false}) =>
      database.transaction(() async {
        TransactionCategory.fromJson(value.toJson());
        final data = await load();
        final categories = TransactionCategoryService.all(data);
        final old = categories.where((v) => v.id == value.id).firstOrNull;
        if ((edit && old == null) || (!edit && old != null)) {
          throw const FormatException(
            'Kategori berubah. Buka kembali daftar kategori.',
          );
        }
        if (old != null && old.kind != value.kind) {
          throw const FormatException('Jenis kategori tidak dapat diubah.');
        }
        if (categories.any((v) => v.id != value.id && v.key == value.key)) {
          throw const FormatException(
            'Nama kategori sudah ada pada jenis ini, termasuk arsip.',
          );
        }
        if (old != null && old.name != value.name) {
          for (final tx in data.transactions.where(
            (t) => categoryKey(t.kind, t.category) == old.key,
          )) {
            final next = LedgerTransaction.fromJson({
              ...tx.toJson(),
              'category': value.name,
            });
            await database.customStatement(
              'UPDATE ledger_transactions SET body = ? WHERE id = ?',
              [jsonEncode(next.toJson()), tx.id],
            );
          }
          for (final rule in data.schedules.where(
            (s) => categoryKey(s.kind, s.category) == old.key,
          )) {
            final next = ScheduleRule.fromJson({
              ...rule.toJson(),
              'category': value.name,
            });
            await database.customStatement(
              'UPDATE schedules SET body = ? WHERE id = ?',
              [jsonEncode(next.toJson()), rule.id],
            );
          }
        }
        await _writeExtras(
          data.extras.copy(
            categories: List.unmodifiable([
              for (final category in categories)
                if (category.id == value.id) value else category,
              if (old == null) value,
            ]),
          ),
        );
        (await load()).validate();
      });

  Future<void> _rememberCategories(LedgerSnapshot data) async {
    // Persist typed and legacy categories too, even if their last transaction
    // is later deleted. Explicit archived entries always win over derived names.
    final categories = TransactionCategoryService.all(data);
    if (data.extras.categories?.length == categories.length) return;
    await _writeExtras(
      data.extras.copy(categories: List.unmodifiable(categories)),
    );
  }

  Future<void> saveInstrument(Instrument value) => updateExtras(
    (data) => data.copy(
      instruments: [...data.instruments.where((v) => v.id != value.id), value],
    ),
  );
  Future<void> ensureDefaultInstruments(List<Instrument> defaults) =>
      database.transaction(() async {
        final data = await load();
        final missing = defaults
            .where(
              (d) => !data.extras.instruments.any(
                (i) =>
                    i.id == d.id ||
                    (i.kind == d.kind && i.priceSymbol == d.providerId),
              ),
            )
            .toList();
        if (missing.isEmpty) return;
        final next = data.extras.copy(
          instruments: [...data.extras.instruments, ...missing],
        );
        data.withExtras(next).validate();
        await _writeExtras(next);
      });
  Future<void> saveStakingPlan(StakingPlan plan) => updateExtras((data) {
    final old = data.stakingPlans.where((p) => p.id == plan.id).firstOrNull;
    if (old != null &&
        data.events.any((e) => e.stakingId == plan.id) &&
        (old.accountId != plan.accountId ||
            old.instrumentId != plan.instrumentId)) {
      throw const FormatException(
        'Lokasi dan crypto posisi yang memiliki riwayat tidak dapat diganti. Buat posisi baru.',
      );
    }
    return data.copy(
      stakingPlans: [...data.stakingPlans.where((p) => p.id != plan.id), plan],
    );
  });
  Future<void> saveInvestment(InvestmentEvent value) => updateExtras(
    (data) => data.copy(
      events: [...data.events.where((v) => v.id != value.id), value],
    ),
  );
  Future<void> deleteInvestment(String id) => updateExtras(
    (data) => data.copy(events: data.events.where((v) => v.id != id).toList()),
  );
  Future<void> saveQuotes(List<PriceQuote> values) => updateExtras(
    (data) => data.copy(
      quotes: [
        ...data.quotes.where((q) => !values.any((v) => v.key == q.key)),
        ...values,
      ],
    ),
  );
  Future<void> saveRate(FxRate rate) => updateExtras(
    (data) => data.copy(
      rates: [
        ...data.rates.where((v) => v.currency != rate.currency),
        if (data.rates.where((v) => v.currency == rate.currency).firstOrNull
            case final old? when old.date.compareTo(rate.date) > 0)
          old
        else
          rate,
      ],
      rateHistory: [
        ...data.rateHistory.where(
          (v) => !(v.currency == rate.currency && v.date == rate.date),
        ),
        ...data.rates.where(
          (v) =>
              !data.rateHistory.any(
                (h) => h.currency == v.currency && h.date == v.date,
              ) &&
              !(v.currency == rate.currency && v.date == rate.date),
        ),
        rate,
      ],
    ),
  );
  Future<void> saveInterestRule(InterestRule rule) => updateExtras(
    (data) => data.copy(
      interestRules: [
        ...data.interestRules.where((v) => v.id != rule.id),
        rule,
      ],
    ),
  );
  Future<bool> postInterest(InterestPosting posting) =>
      database.transaction(() async {
        final data = await load();
        if (data.extras.interestPostings.any((v) => v.id == posting.id)) {
          return false;
        }
        final next = data.extras.copy(
          interestPostings: [...data.extras.interestPostings, posting],
        );
        data.withExtras(next).validate();
        await _writeExtras(next);
        return true;
      });
  Future<void> voidInterest(String id) => updateExtras(
    (data) => data.copy(
      interestPostings: data.interestPostings
          .map(
            (p) => p.id != id
                ? p
                : InterestPosting.fromJson({...p.toJson(), 'voided': true}),
          )
          .toList(),
    ),
  );
  Future<void> processInterest(DateTime now) => database.transaction(() async {
    // Re-evaluate after every credit so daily compounding uses actual postings.
    for (var n = 0; n < 100; n++) {
      final data = await load();
      final next = InterestEngine.pending(
        data,
        now,
        automaticOnly: true,
        maxPerRule: 1,
      ).firstOrNull;
      if (next == null) return;
      await postInterest(next);
    }
    // Catch-up continues on the next foreground refresh instead of blocking startup.
  });

  Future<void> addAccount(Account account) async {
    Account.fromJson(account.toJson());
    await database.customStatement(
      'INSERT INTO accounts(id, body) VALUES (?, ?)',
      [account.id, jsonEncode(account.toJson())],
    );
  }

  Future<void> saveCard(PaymentCard card) => database.transaction(() async {
    PaymentCard.fromJson(card.toJson());
    final data = await load();
    if (!data.accounts.any(
      (a) => a.id == card.accountId && a.kind == AccountKind.bank,
    )) {
      throw const FormatException('Pilih rekening bank sumber kartu.');
    }
    await database.customStatement(
      'INSERT OR REPLACE INTO payment_cards(id,body) VALUES (?, ?)',
      [card.id, jsonEncode(card.toJson())],
    );
  });

  Future<void> saveTransaction(
    LedgerTransaction tx, {
    bool edit = false,
    bool preserveHistoricalCard = false,
  }) => database.transaction(() async {
    LedgerTransaction.fromJson(tx.toJson());
    final accounts = await database
        .customSelect('SELECT id FROM accounts')
        .get();
    final ids = accounts.map((a) => a.read<String>('id')).toSet();
    if (!ids.contains(tx.accountId) ||
        (tx.destinationId != null && !ids.contains(tx.destinationId))) {
      throw const FormatException('Aset tidak ditemukan.');
    }
    if (tx.cardId != null) {
      final data = await load();
      final card = data.cards.where((c) => c.id == tx.cardId).firstOrNull;
      final old = edit
          ? data.transactions.where((t) => t.id == tx.id).firstOrNull
          : null;
      final historical =
          old?.cardId == tx.cardId && old?.accountId == tx.accountId;
      if (card == null ||
          (!preserveHistoricalCard &&
              !historical &&
              card.accountId != tx.accountId)) {
        throw const FormatException(
          'Kartu tidak terhubung ke rekening sumber ini.',
        );
      }
    }
    if (edit) {
      final existing = await database
          .customSelect(
            'SELECT id FROM ledger_transactions WHERE id = ?',
            variables: [Variable<String>(tx.id)],
          )
          .get();
      if (existing.isEmpty) {
        throw const FormatException('Transaksi tidak ditemukan.');
      }
      await database.customStatement(
        '''UPDATE ledger_transactions SET account_id = ?,
          destination_id = ?, date = ?, body = ? WHERE id = ?''',
        [
          tx.accountId,
          tx.destinationId,
          tx.date,
          jsonEncode(tx.toJson()),
          tx.id,
        ],
      );
    } else {
      await database.customStatement(
        '''INSERT INTO ledger_transactions
          (id, account_id, destination_id, date, body) VALUES (?, ?, ?, ?, ?)''',
        [
          tx.id,
          tx.accountId,
          tx.destinationId,
          tx.date,
          jsonEncode(tx.toJson()),
        ],
      );
    }
    final saved = await load();
    saved.validate();
    await _rememberCategories(saved);
  });

  Future<void> deleteTransaction(String id) => database.transaction(() async {
    await _rememberCategories(await load());
    final rows = await database
        .customSelect(
          'SELECT body FROM schedule_occurrences WHERE transaction_id = ?',
          variables: [Variable<String>(id)],
        )
        .get();
    for (final row in rows) {
      final old = ScheduleOccurrence.fromJson(
        objectMap(jsonDecode(row.read<String>('body'))),
      );
      final deleted = ScheduleOccurrence(
        scheduleId: old.scheduleId,
        ordinal: old.ordinal,
        dueDate: old.dueDate,
        state: OccurrenceState.deleted,
        resolvedAt: old.resolvedAt,
      );
      await database.customStatement(
        'UPDATE schedule_occurrences SET transaction_id = NULL, body = ? WHERE schedule_id = ? AND ordinal = ?',
        [jsonEncode(deleted.toJson()), old.scheduleId, old.ordinal],
      );
    }
    await database.customStatement(
      'DELETE FROM ledger_transactions WHERE id = ?',
      [id],
    );
  });

  Future<void> saveSchedule(
    ScheduleRule rule, {
    String? replacesId,
    int? replacesResolvedCount,
    DateTime? processAt,
  }) => database.transaction(() async {
    ScheduleRule.fromJson(rule.toJson());
    final data = await load();
    LedgerSnapshot(
      accounts: data.accounts,
      transactions: data.transactions,
      schedules: [...data.schedules, rule],
      cards: data.cards,
      extras: data.extras,
      occurrences: data.occurrences,
    ).validate();
    if (replacesId != null) {
      final old = data.schedules.where((s) => s.id == replacesId).firstOrNull;
      if (old == null || old.state == ScheduleState.stopped) {
        throw const FormatException(
          'Jadwal lama sudah dihentikan atau tidak ditemukan.',
        );
      }
      if (replacesResolvedCount != null &&
          data.occurrences.where((o) => o.scheduleId == replacesId).length !=
              replacesResolvedCount) {
        throw const FormatException(
          'Riwayat jadwal berubah saat formulir dibuka. Buka kembali formulir untuk meninjau sisa jadwal terbaru.',
        );
      }
      await _writeScheduleState(old, ScheduleState.stopped);
    }
    await database.customStatement(
      'INSERT INTO schedules(id, body) VALUES (?, ?)',
      [rule.id, jsonEncode(rule.toJson())],
    );
    await _rememberCategories(await load());
    if (processAt != null) await processAutomatic(processAt);
  });

  Future<void> _writeScheduleState(ScheduleRule rule, ScheduleState state) =>
      database.customStatement('UPDATE schedules SET body = ? WHERE id = ?', [
        jsonEncode(rule.withState(state).toJson()),
        rule.id,
      ]);

  Future<void> setScheduleState(
    String id,
    ScheduleState state,
    DateTime now, {
    bool skipMissed = false,
  }) => database.transaction(() async {
    final data = await load();
    final rule = data.schedules.where((s) => s.id == id).firstOrNull;
    if (rule == null || rule.state == ScheduleState.stopped) {
      throw const FormatException(
        'Jadwal sudah dihentikan atau tidak ditemukan.',
      );
    }
    if (state == ScheduleState.active && skipMissed) {
      for (final item in ScheduleEngine.pending(
        rule,
        data.occurrences,
        through: localDate(
          DateTime.parse('${rule.today(now)}T00:00:00Z')
              .subtract(const Duration(days: 1)),
        ),
        limit: 110001,
      )) {
        await _insertOccurrence(
          ScheduleOccurrence(
            scheduleId: id,
            ordinal: item.ordinal,
            dueDate: item.date,
            state: OccurrenceState.skipped,
            resolvedAt: now.toUtc().toIso8601String(),
          ),
        );
      }
    }
    await _writeScheduleState(rule, state);
    if (state == ScheduleState.active) await processAutomatic(now);
  });

  Future<void> _insertOccurrence(ScheduleOccurrence occurrence) =>
      database.customStatement(
        'INSERT INTO schedule_occurrences(schedule_id,ordinal,transaction_id,body) VALUES (?, ?, ?, ?)',
        [
          occurrence.scheduleId,
          occurrence.ordinal,
          occurrence.transactionId,
          jsonEncode(occurrence.toJson()),
        ],
      );

  /// Identity is checked under the same SQLite transaction as the ledger insert.
  /// Returns false for a repeated request, including a deliberately deleted item.
  Future<bool> resolveOccurrence(
    String id,
    int ordinal,
    DateTime now, {
    bool skip = false,
    Money? amount,
    Money? fee,
    Money? receiverFee,
    String? date,
    String? note,
    String? time,
  }) => database.transaction(() async {
    final existing = await database
        .customSelect(
          'SELECT ordinal FROM schedule_occurrences WHERE schedule_id = ? AND ordinal = ?',
          variables: [Variable<String>(id), Variable<int>(ordinal)],
        )
        .get();
    if (existing.isNotEmpty) return false;
    final rows = await database
        .customSelect(
          'SELECT body FROM schedules WHERE id = ?',
          variables: [Variable<String>(id)],
        )
        .get();
    if (rows.isEmpty) throw const FormatException('Jadwal tidak ditemukan.');
    final rule = ScheduleRule.fromJson(
      objectMap(jsonDecode(rows.single.read<String>('body'))),
    );
    final due = rule.dateAt(ordinal);
    if (rule.state != ScheduleState.active || due == null) {
      throw const FormatException(
        'Jadwal tidak aktif atau kejadian tidak valid.',
      );
    }
    final stamp = now.toUtc().toIso8601String();
    final transactionId = skip ? null : 'schedule:$id:$ordinal';
    if (!skip) {
      final effectiveDate =
          date ?? (due.compareTo(rule.today(now)) > 0 ? rule.today(now) : due);
      validateDate(effectiveDate);
      if (effectiveDate.compareTo(rule.today(now)) > 0) {
        throw const FormatException(
          'Tanggal pencatatan tidak boleh melewati hari ini pada zona jadwal.',
        );
      }
      await saveTransaction(
        LedgerTransaction(
          id: transactionId!,
          kind: rule.kind,
          accountId: rule.accountId,
          destinationId: rule.destinationId,
          amount: amount ?? rule.amountAt(ordinal),
          fee: fee ?? rule.fee,
          receiverFee: receiverFee ?? rule.receiverFee,
          date: effectiveDate,
          category: rule.category,
          note: note ?? rule.note,
          createdAt: stamp,
          time: time ?? rule.time,
          zone: rule.zone,
          idrRate:
              (await load()).extras.rate(
                (await load()).accounts
                    .firstWhere((a) => a.id == rule.accountId)
                    .currency,
              ) ??
              (throw const FormatException(
                'Isi kurs aset sebelum memproses jadwal.',
              )),
        ),
      );
    }
    await _insertOccurrence(
      ScheduleOccurrence(
        scheduleId: id,
        ordinal: ordinal,
        dueDate: due,
        state: skip ? OccurrenceState.skipped : OccurrenceState.posted,
        transactionId: transactionId,
        resolvedAt: stamp,
      ),
    );
    return true;
  });

  Future<void> processAutomatic(DateTime now) => database.transaction(() async {
    final data = await load();
    for (final rule in data.schedules.where(
      (s) =>
          s.state == ScheduleState.active && s.mode == ScheduleMode.automatic,
    )) {
      final currency = data.accounts
          .firstWhere((a) => a.id == rule.accountId)
          .currency;
      if (data.extras.rate(currency) == null) {
        continue;
      }
      for (final item in ScheduleEngine.pending(
        rule,
        data.occurrences,
        through: rule.today(now),
        limit: 110001,
      )) {
        if (item.isDue(now)) {
          await resolveOccurrence(rule.id, item.ordinal, now);
        }
      }
    }
  });

  Future<void> setTheme(String value) async {
    if (!{'dark', 'light', 'system'}.contains(value)) {
      throw const FormatException('Tema tidak valid.');
    }
    await database.customStatement(
      'INSERT OR REPLACE INTO preferences(key, value) VALUES (?, ?)',
      ['theme', value],
    );
  }

  Future<String?> preference(String key) async {
    final rows = await database
        .customSelect(
          'SELECT value FROM preferences WHERE key = ?',
          variables: [Variable<String>(key)],
        )
        .get();
    return rows.firstOrNull?.read<String>('value');
  }

  Future<void> setPreference(String key, String value) =>
      database.customStatement(
        'INSERT OR REPLACE INTO preferences(key,value) VALUES (?,?)',
        [key, value],
      );

  /// Preferensi privasi perangkat tidak dibagikan melalui file backup.
  Future<bool> amountsHidden() async {
    final rows = await database
        .customSelect(
          "SELECT value FROM preferences WHERE key = 'amounts_hidden'",
        )
        .get();
    return rows.isNotEmpty && rows.first.read<String>('value') == 'true';
  }

  Future<void> setAmountsHidden(bool hidden) => database.customStatement(
    'INSERT OR REPLACE INTO preferences(key, value) VALUES (?, ?)',
    ['amounts_hidden', hidden.toString()],
  );

  /// Seluruh penggantian dilakukan atomik. Validasi gagal tidak menghapus data.
  Future<void> replace(LedgerSnapshot snapshot, {DateTime? processAt}) async {
    snapshot.validate();
    await database.transaction(() async {
      await database.customStatement('DELETE FROM schedule_occurrences');
      await database.customStatement('DELETE FROM schedules');
      await database.customStatement('DELETE FROM ledger_transactions');
      await database.customStatement('DELETE FROM payment_cards');
      await database.customStatement('DELETE FROM accounts');
      await database.customStatement('DELETE FROM finance_extras');
      await database.customStatement(
        "DELETE FROM preferences WHERE key NOT IN ('amounts_hidden','sheet_csv_url','market_auto','market_last_attempt','market_daily_auto')",
      );
      for (final account in snapshot.accounts) {
        await addAccount(account);
      }
      await _writeExtras(snapshot.extras);
      for (final card in snapshot.cards) {
        await database.customStatement(
          'INSERT INTO payment_cards(id,body) VALUES (?, ?)',
          [card.id, jsonEncode(card.toJson())],
        );
      }
      // Dibalik agar urutan transaksi dengan tanggal sama tetap stabil saat load.
      for (final tx in snapshot.transactions.reversed) {
        // The complete snapshot, including historical cards and FX, was
        // validated before this atomic transaction. Re-reading all price and
        // investment history for every row makes a large restore quadratic.
        await database.customStatement(
          '''INSERT INTO ledger_transactions
            (id, account_id, destination_id, date, body) VALUES (?, ?, ?, ?, ?)''',
          [
            tx.id,
            tx.accountId,
            tx.destinationId,
            tx.date,
            jsonEncode(tx.toJson()),
          ],
        );
      }
      for (final rule in snapshot.schedules) {
        await database.customStatement(
          'INSERT INTO schedules(id,body) VALUES (?, ?)',
          [rule.id, jsonEncode(rule.toJson())],
        );
      }
      for (final occurrence in snapshot.occurrences) {
        await _insertOccurrence(occurrence);
      }
      await setTheme(snapshot.theme);
      if (processAt != null) await processAutomatic(processAt);
    });
  }
}
