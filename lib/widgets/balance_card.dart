import 'package:material_ui/material_ui.dart';

import '../models/money.dart';
import 'arta_icon.dart';

/// Formatting only. Ledger values remain exact BigInts, including in exports.
String abbreviatedMoney(Money money) {
  final n = money.minor.abs(), sign = money.isNegative ? '-' : '';
  for (final (unit, suffix) in [
    (100000000000000, 'T'),
    (100000000000, 'M'),
    (100000000, 'jt'),
  ]) {
    final base = BigInt.from(unit);
    if (n >= base) {
      final hundredths = (n * BigInt.from(100) + base ~/ BigInt.two) ~/ base;
      final fraction = (hundredths % BigInt.from(100)).toString().padLeft(
        2,
        '0',
      );
      return '${sign}Rp ${hundredths ~/ BigInt.from(100)},$fraction $suffix';
    }
  }
  return money.formatted;
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.value, {
    super.key,
    this.hidden = false,
    this.style,
    this.currency = 'IDR',
    this.onTap,
  });
  final Money value;
  final bool hidden;
  final TextStyle? style;
  final String currency;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final effective = DefaultTextStyle.of(context).style.merge(style);
      final full = hidden
          ? '••••••'
          : value.formatted.replaceFirst(
              'Rp ',
              currency == 'IDR' ? 'Rp ' : '$currency ',
            );
      final painter = TextPainter(
        text: TextSpan(text: full, style: effective),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final compact =
          !hidden && box.maxWidth.isFinite && painter.width > box.maxWidth;
      final label = compact
          ? abbreviatedMoney(value)
                .replaceFirst('Rp ', currency == 'IDR' ? 'Rp ' : '$currency ')
          : full;
      return Semantics(
        label: hidden ? 'Nominal disembunyikan' : full,
        child: InkWell(
          onTap: hidden ? null : onTap,
          child: Text(label, style: effective, softWrap: true),
        ),
      );
    },
  );
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.assets,
    required this.liabilities,
    this.hidden = false,
    this.onToggle,
  });
  final Money assets, liabilities;
  final bool hidden;
  final VoidCallback? onToggle;
  void details(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rincian nominal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            for (final (label, value) in [
              ('Aset', assets),
              ('Liabilitas', liabilities),
              ('Total', assets - liabilities),
            ]) ...[
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              SelectableText(
                value.formatted,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Total dihitung dari nilai utuh sebelum pembulatan tampilan.',
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    Widget item(String label, Money value, {bool debt = false}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        MoneyText(
          value,
          hidden: hidden,
          onTap: () => details(context),
          style: theme.textTheme.titleMedium?.copyWith(
            color: debt ? colors.error : colors.onSurface,
          ),
        ),
      ],
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, box) =>
                  MediaQuery.textScalerOf(context).scale(12) > 24 &&
                      box.maxWidth < 320
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        item('Aset', assets),
                        const SizedBox(height: 12),
                        item('Liabilitas', liabilities, debt: true),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: item('Aset', assets)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: item('Liabilitas', liabilities, debt: true),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aset − Liabilitas',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  key: const Key('toggle-amounts'),
                  tooltip: hidden ? 'Tampilkan nominal' : 'Sembunyikan nominal',
                  onPressed: onToggle,
                  icon: DesignGlyph(hidden ? 'eye-off' : 'eye', size: 22),
                ),
              ],
            ),
            MoneyText(
              assets - liabilities,
              hidden: hidden,
              onTap: () => details(context),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: (assets - liabilities).isNegative
                    ? colors.error
                    : colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
