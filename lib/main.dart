import 'widgets/arta_icon.dart';
import 'config/app_info.dart';

import 'package:feather_icons/feather_icons.dart';

import 'dart:io';
import 'dart:developer' as developer;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show LicenseRegistry, LicenseEntryWithLineBreaks;

import 'app.dart';
import 'controllers/finance_controller.dart';
import 'database/app_database.dart';
import 'repositories/finance_repository.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/arta_logo.dart';
import 'controllers/app_lock_controller.dart';
import 'services/app_lock_service.dart';
import 'services/catalog_service.dart';
import 'models/investment.dart';
import 'models/ledger.dart';
import 'services/reference_prices_service.dart';
import 'repositories/benchmark_repository.dart';

import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      ['idn-finlogos'],
      await rootBundle.loadString(
        'assets/ui/licenses/idn-finlogos-LICENSE-ASSETS.txt',
      ),
    );
    yield LicenseEntryWithLineBreaks(
      ['idn-finlogos'],
      await rootBundle.loadString('assets/ui/licenses/idn-finlogos-NOTICE.txt'),
    );
  });
  runApp(const BootstrapScreen());
}

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key, this.databaseFile});
  final Future<File> Function()? databaseFile;
  @override
  State<BootstrapScreen> createState() => _BootstrapState();
}

class _BootstrapState extends State<BootstrapScreen> {
  FinanceController? controller;
  AppDatabase? database;
  String? error;
  String? details;
  bool opening = false;
  @override
  void initState() {
    super.initState();
    open();
  }

  Future<void> open() async {
    if (opening || controller != null) return;
    setState(() {
      opening = true;
      error = null;
      details = null;
    });
    AppDatabase? candidate;
    FinanceController? next;
    var stage = 'Direktori privat aplikasi';
    try {
      final file =
          await (widget.databaseFile?.call() ??
              LocalStorageService().databaseFile());
      if (!mounted) return;
      stage = 'Membuka SQLite';
      final db = AppDatabase.file(file);
      candidate = db;
      // Force opening/migration here so retry closes the failed connection and
      // diagnostic details retain the actual native error.
      await db.customSelect('SELECT 1').getSingle();
      stage = 'Memuat catatan';
      final security = AppLockController(AndroidAppLockService());
      await security.initialize();
      final repository = FinanceRepository(db);
      if (!(await repository.load()).extras.instruments.any(
        (i) => i.kind == InstrumentKind.stock,
      )) {
        final seed = await rootBundle.loadString('assets/data/idx_stocks.json');
        final preview = CatalogService()
            .parse(Uint8List.fromList(utf8.encode(seed)), 'idx_stocks.json')
            .single;
        await repository.updateExtras(
          (data) => preview.apply(
            data,
            'IDX bawaan · unduhan 2026-11-18',
            DateTime.now(),
          ),
        );
      }
      final cryptoSeed = jsonDecode(
        await rootBundle.loadString('assets/data/crypto_defaults.json'),
      ) as List<Object?>;
      await repository.ensureDefaultInstruments(
        cryptoSeed.map((v) => Instrument.fromJson(objectMap(v))).toList(),
      );
      next = FinanceController(
        repository,
        security: security,
        references: ReferencePricesService(),
        benchmarks: BenchmarkRepository(db),
      );
      await next.initialize();
      if (!mounted) {
        next.dispose();
        await db.close();
        return;
      }
      setState(() {
        database = db;
        controller = next;
      });
    } catch (cause, stack) {
      next?.dispose();
      try {
        await candidate?.close();
      } catch (_) {
        /* Preserve the original failure. */
      }
      developer.log(
        'Startup failed at $stage',
        name: 'arta.startup',
        error: cause,
        stackTrace: stack,
      );
      if (mounted) {
        setState(() {
          error = 'Penyimpanan lokal belum dapat dibuka.';
          details =
              'Arta $appVersion\nTahap: $stage\n${cause.runtimeType}: $cause';
        });
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    database?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null) return ArtaApp(controller: controller!);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.create(Brightness.dark),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ArtaLogo(loading: opening),
                    const SizedBox(height: 24),
                    Text(error ?? 'Memuat Arta…', textAlign: TextAlign.center),
                    if (details != null)
                      ExpansionTile(
                        key: const Key('startup-details'),
                        title: const Text('Rincian error'),
                        children: [
                          SelectableText(details!),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: details!),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rincian error disalin.'),
                                  ),
                                );
                              }
                            },
                            icon: const ArtaIcon(FeatherIcons.copy),
                            label: const Text('Salin rincian'),
                          ),
                        ],
                      ),
                    if (error != null)
                      TextButton(
                        key: const Key('startup-retry'),
                        onPressed: opening ? null : open,
                        child: const Text('Coba lagi'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
