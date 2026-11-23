import 'decimal.dart';
import 'ledger.dart';

/// A manual tracking position. No wallet credentials or blockchain connection.
final class StakingPlan {
  const StakingPlan({
    required this.id,
    required this.accountId,
    required this.instrumentId,
    required this.name,
    this.validator = '',
    this.network = '',
    this.apr,
    this.archived = false,
  });
  final String id, accountId, instrumentId, name, validator, network;
  final Decimal? apr;
  final bool archived;
  Map<String, Object?> toJson() => {
    'id': id,
    'account_id': accountId,
    'instrument_id': instrumentId,
    'name': name,
    'validator': validator,
    'network': network,
    'apr': apr?.text,
    'archived': archived,
  };
  factory StakingPlan.fromJson(Map<String, Object?> j) {
    exactKeys(j, {
      'id',
      'account_id',
      'instrument_id',
      'name',
      'validator',
      'network',
      'apr',
      'archived',
    });
    final p = StakingPlan(
      id: stringField(j, 'id'),
      accountId: stringField(j, 'account_id'),
      instrumentId: stringField(j, 'instrument_id'),
      name: stringField(j, 'name'),
      validator: stringField(j, 'validator', empty: true),
      network: stringField(j, 'network', empty: true),
      apr: j['apr'] == null ? null : Decimal.parse(stringField(j, 'apr')),
      archived: boolField(j, 'archived'),
    );
    if (p.name.length > 200 ||
        p.validator.length > 200 ||
        p.network.length > 200 ||
        (p.apr != null &&
            (p.apr!.negative ||
                p.apr!.compareTo(Decimal.parse('10000')) > 0))) {
      throw const FormatException('Informasi staking tidak valid.');
    }
    return p;
  }
}

final class StakingBalance {
  StakingBalance();
  Decimal staked = Decimal.zero;
  Decimal pending = Decimal.zero;
  Decimal rewards = Decimal.zero;
  Decimal losses = Decimal.zero;
  Decimal get locked => staked + pending;
}
