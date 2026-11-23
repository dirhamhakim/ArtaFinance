import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

import '../models/ledger.dart';
import 'arta_icon.dart';

class AssetProvider {
  const AssetProvider(this.id, this.name, this.kind);
  final String id, name;
  final AccountKind kind;
}

const assetProviders = [
  AssetProvider('bca', 'BCA', AccountKind.bank),
  AssetProvider('bni', 'BNI', AccountKind.bank),
  AssetProvider('bri', 'BRI', AccountKind.bank),
  AssetProvider('mandiri', 'Mandiri', AccountKind.bank),
  AssetProvider('jago', 'Jago / Jago Syariah', AccountKind.bank),
  AssetProvider('seabank', 'SeaBank', AccountKind.bank),
  AssetProvider('dana', 'DANA', AccountKind.ewallet),
  AssetProvider('doku', 'DOKU', AccountKind.ewallet),
  AssetProvider('gopay', 'GoPay', AccountKind.ewallet),
  AssetProvider('linkaja', 'LinkAja', AccountKind.ewallet),
  AssetProvider('ovo', 'OVO', AccountKind.ewallet),
  AssetProvider('shopee-pay', 'ShopeePay', AccountKind.ewallet),
];

String? inferredProvider(String name) {
  final normal = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return assetProviders
      .where(
        (p) => p.id.length <= 3
            ? name.toLowerCase().split(RegExp(r'[^a-z0-9]+')).contains(p.id)
            : normal.contains(p.id.replaceAll('-', '')),
      )
      .firstOrNull
      ?.id;
}

class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    super.key,
    this.provider,
    this.name = '',
    required this.kind,
    this.size = 40,
  });
  final String? provider;
  final String name;
  final AccountKind kind;
  final double size;
  @override
  Widget build(BuildContext context) {
    final canInfer = [
      AccountKind.bank,
      AccountKind.ewallet,
      AccountKind.debit,
    ].contains(kind);
    final id = provider == 'other'
        ? null
        : provider ?? (canInfer ? inferredProvider(name) : null);
    final available = assetProviders.any((p) => p.id == id);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(available ? 6 : 8),
      decoration: BoxDecoration(
        color: available
            ? Colors.white
            : Theme.of(context).colorScheme.primary.withValues(alpha: .15),
        shape: BoxShape.circle,
      ),
      child: available
          ? SvgPicture.asset('assets/ui/providers/$id.svg')
          : DesignGlyph(
              switch (kind) {
                AccountKind.bank => 'bank',
                AccountKind.cash => 'cash',
                AccountKind.ewallet => 'wallet',
                AccountKind.debit || AccountKind.liability => 'card',
                AccountKind.exchange => 'exchange',
                AccountKind.receivable => 'receivable',
              },
              color: Theme.of(context).colorScheme.primary,
              size: size * .55,
            ),
    );
  }
}

Future<String?> pickAssetProvider(BuildContext context, AccountKind kind) =>
    showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _ProviderSheet(kind: kind),
    );

class _ProviderSheet extends StatefulWidget {
  const _ProviderSheet({required this.kind});
  final AccountKind kind;
  @override
  State<_ProviderSheet> createState() => _ProviderSheetState();
}

class _ProviderSheetState extends State<_ProviderSheet> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final rows = assetProviders
        .where(
          (p) =>
              (widget.kind == AccountKind.debit
                  ? p.kind == AccountKind.bank
                  : p.kind == widget.kind) &&
              p.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pilih bank / e-wallet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari penyedia',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(16),
                          child: DesignGlyph('search', size: 20),
                        ),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final p in rows)
                      ListTile(
                        leading: ProviderLogo(provider: p.id, kind: p.kind),
                        title: Text(p.name),
                        onTap: () => Navigator.pop(context, p.id),
                      ),
                    ListTile(
                      leading: ProviderLogo(
                        provider: 'other',
                        kind: widget.kind,
                      ),
                      title: const Text('Lainnya'),
                      subtitle: const Text(
                        'Gunakan nama sendiri dan ikon tetap',
                      ),
                      onTap: () => Navigator.pop(context, 'other'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
