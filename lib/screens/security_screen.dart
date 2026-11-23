import '../widgets/finance_dialog.dart';
import '../widgets/arta_icon.dart';

import 'package:material_ui/material_ui.dart';

import '../controllers/app_lock_controller.dart';
import '../widgets/pin_keypad.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key, required this.controller});
  final AppLockController controller;
  Future<void> setup(BuildContext context) async {
    if (!await controller.authorizeChange() || !context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PinSetupScreen(controller: controller)),
    );
  }

  Future<void> disable(BuildContext context) async {
    if (!await controller.authorizeChange() || !context.mounted) return;
    final accepted = await showFinanceDialog<bool>(
      context: context,
      builder: (context) => FinanceDialog(
        title: const Text('Nonaktifkan kunci aplikasi?'),
        content: const Text(
          'Arta akan langsung terbuka tanpa sidik jari atau PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
    if (accepted == true) await controller.disable();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Kunci aplikasi')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const ArtaIcon(Icons.fingerprint, size: 72),
                const SizedBox(height: 20),
                Text(
                  controller.status.enabled
                      ? 'Kunci aplikasi aktif'
                      : 'Kunci aplikasi opsional',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gunakan sidik jari HP sebagai pilihan utama dan PIN Arta 6 angka sebagai cadangan. PIN Arta terpisah dari PIN layar kunci HP.',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  key: const Key('configure-app-lock'),
                  onPressed: controller.busy ? null : () => setup(context),
                  child: Text(
                    controller.status.enabled
                        ? 'Ubah PIN / pilihan sidik jari'
                        : 'Aktifkan kunci aplikasi',
                  ),
                ),
                if (controller.status.enabled) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: controller.busy ? null : () => disable(context),
                    child: const Text('Nonaktifkan kunci aplikasi'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: controller.busy ? null : controller.lock,
                    child: const Text('Kunci sekarang'),
                  ),
                ],
                if (controller.error != null)
                  Text(
                    controller.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 24),
                const Text(
                  'Kunci aktif kembali ketika aplikasi masuk latar belakang, termasuk saat membuka pemilih foto atau file. Data form tetap ada setelah dibuka kembali.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Simpan backup terenkripsi sebelum mengaktifkan kunci. Jika lupa PIN dan sidik jari tidak bisa dipakai, tidak ada jalur pemulihan online. Pemulihan memerlukan backup milik Anda setelah menghapus data aplikasi.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, required this.controller});
  final AppLockController controller;
  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? first, error;
  bool biometric = true, saving = false;
  int attempt = 0;
  Future<void> complete(String pin) async {
    if (first == null) {
      setState(() {
        first = pin;
        error = null;
        attempt++;
      });
      return;
    }
    if (first != pin) {
      setState(() {
        first = null;
        error = 'PIN berbeda. Buat ulang PIN Anda.';
        attempt++;
      });
      return;
    }
    setState(() => saving = true);
    final ok = await widget.controller.configure(
      pin,
      biometric && widget.controller.status.available,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        saving = false;
        first = null;
        error = widget.controller.error;
        attempt++;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PIN Arta')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                first == null ? 'Buat PIN 6 angka' : 'Ulangi PIN Anda',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gunakan PIN khusus aplikasi ini.',
                textAlign: TextAlign.center,
              ),
              if (error != null)
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              PinKeypad(
                key: ValueKey(attempt),
                enabled: !saving,
                onComplete: complete,
              ),
              SwitchListTile.adaptive(
                key: const Key('prefer-biometric'),
                value: biometric && widget.controller.status.available,
                onChanged:
                    saving ||
                        !widget.controller.status.available ||
                        first != null
                    ? null
                    : (v) => setState(() => biometric = v),
                title: const Text('Utamakan sidik jari'),
                subtitle: Text(
                  widget.controller.status.available
                      ? 'Gunakan sidik jari HP; PIN Arta tetap tersedia'
                      : 'Daftarkan sidik jari pada pengaturan HP terlebih dahulu',
                ),
              ),
              if (saving)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Menyimpan keamanan…'),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
