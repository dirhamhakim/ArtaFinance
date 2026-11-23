import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'arta_icon.dart';

class PinKeypad extends StatefulWidget {
  const PinKeypad({
    super.key,
    required this.onComplete,
    this.enabled = true,
    this.onBiometric,
    this.onForgot,
    this.fullPage = false,
    this.error,
    this.retrySeconds = 0,
  });
  final Future<void> Function(String) onComplete;
  final bool enabled, fullPage;
  final VoidCallback? onBiometric, onForgot;
  final String? error;
  final int retrySeconds;
  @override
  State<PinKeypad> createState() => _PinKeypadState();
}

class _PinKeypadState extends State<PinKeypad> {
  String digits = '';
  bool submitting = false, visible = false;
  Future<void> complete() async {
    if (!widget.enabled ||
        submitting ||
        digits.length != 6 ||
        widget.retrySeconds > 0) {
      return;
    }
    setState(() => submitting = true);
    try {
      await widget.onComplete(digits);
    } finally {
      if (mounted) {
        setState(() {
          digits = '';
          submitting = false;
        });
      }
    }
  }

  void press(String digit) {
    if (!widget.enabled ||
        submitting ||
        digits.length >= 6 ||
        widget.retrySeconds > 0) {
      return;
    }
    setState(() => digits += digit);
    if (digits.length == 6 && !widget.fullPage) complete();
  }

  Widget field(BuildContext context) => Semantics(
    label: '${digits.length} dari 6 angka PIN terisi',
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: ExcludeSemantics(
              child: Text(
                visible ? digits : List.filled(digits.length, '•').join(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, letterSpacing: 10),
              ),
            ),
          ),
          IconButton(
            tooltip: visible ? 'Sembunyikan PIN' : 'Tampilkan PIN',
            onPressed: () => setState(() => visible = !visible),
            icon: DesignGlyph(visible ? 'eye-off' : 'eye', size: 20),
          ),
        ],
      ),
    ),
  );
  Widget grid(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var row = 0; row < 4; row++)
        Row(
          children: [
            for (var col = 0; col < 3; col++)
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: .5,
                        ),
                        left: BorderSide(
                          color: col == 0
                              ? Colors.transparent
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: .5,
                        ),
                      ),
                    ),
                    child: row == 3 && col == 0
                        ? IconButton(
                            key: const Key('pin-fingerprint'),
                            tooltip: 'Gunakan sidik jari',
                            onPressed: widget.enabled
                                ? widget.onBiometric
                                : null,
                            icon: DesignGlyph(
                              'fingerprint',
                              color: widget.onBiometric == null
                                  ? Theme.of(context).colorScheme.outline
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : row == 3 && col == 2
                        ? IconButton(
                            key: const Key('pin-delete'),
                            tooltip: 'Hapus angka PIN terakhir',
                            onPressed:
                                !widget.enabled || submitting || digits.isEmpty
                                ? null
                                : () => setState(
                                    () => digits = digits.substring(
                                      0,
                                      digits.length - 1,
                                    ),
                                  ),
                            icon: const DesignGlyph('backspace', size: 22),
                          )
                        : TextButton(
                            key: Key(
                              'pin-digit-${row == 3 ? 0 : row * 3 + col + 1}',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                              shape: const RoundedRectangleBorder(),
                            ),
                            onPressed: !widget.enabled || submitting
                                ? null
                                : () => press(
                                    '${row == 3 ? 0 : row * 3 + col + 1}',
                                  ),
                            child: Text(
                              '${row == 3 ? 0 : row * 3 + col + 1}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    if (!widget.fullPage) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(context),
              const SizedBox(height: 20),
              grid(context),
            ],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final height = math.max(
          box.maxHeight,
          680.0 +
              math.max(0.0, MediaQuery.textScalerOf(context).scale(14) - 14) *
                  12,
        );
        return SingleChildScrollView(
          child: SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Text(
                  'Verifikasi PIN',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(flex: 2),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary
                        .withValues(alpha: .14),
                  ),
                  child: Center(
                    child: DesignGlyph(
                      'lock',
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Masukkan PIN Kamu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: field(context),
                ),
                if (widget.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Text(
                      widget.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (widget.retrySeconds > 0)
                  Text('Coba lagi dalam ${widget.retrySeconds} detik'),
                const Spacer(flex: 3),
                TextButton(
                  key: const Key('forgot-pin'),
                  onPressed: widget.enabled ? widget.onForgot : null,
                  child: const Text('Lupa PIN?'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          widget.enabled && digits.length == 6 && !submitting
                          ? complete
                          : null,
                      child: const Text('Lanjut'),
                    ),
                  ),
                ),
                grid(context),
              ],
            ),
          ),
        );
      },
    );
  }
}
