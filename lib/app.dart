import 'package:material_ui/material_ui.dart';

import 'controllers/finance_controller.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/arta_logo.dart';
import 'widgets/app_lock_gate.dart';

class ArtaApp extends StatelessWidget {
  static final navigatorKey = GlobalKey<NavigatorState>();
  const ArtaApp({super.key, required this.controller});
  final FinanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Arta',
      debugShowCheckedModeBanner: false,
      locale: const Locale('id'),
      supportedLocales: const [Locale('id')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.create(Brightness.light),
      darkTheme: AppTheme.create(Brightness.dark),
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: controller.security == null
              ? child!
              : AppLockGate(
                  controller: controller.security!,
                  navigatorKey: navigatorKey,
                  child: child!,
                ),
        ),
      ),
      themeMode: switch (controller.snapshot.theme) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      home: controller.ready
          ? HomeScreen(controller: controller)
          : Scaffold(
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ArtaLogo(loading: controller.busy),
                        const SizedBox(height: 24),
                        Text(
                          controller.error ??
                              'Menyiapkan catatan keuangan Anda…',
                          textAlign: TextAlign.center,
                        ),
                        if (!controller.busy && controller.error != null) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: controller.initialize,
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}
