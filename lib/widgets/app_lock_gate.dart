import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../controllers/app_lock_controller.dart';
import 'arta_logo.dart';
import 'pin_keypad.dart';
import '../screens/security_screen.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.controller,
    required this.child,
    this.navigatorKey,
  });
  final GlobalKey<NavigatorState>? navigatorKey;
  final AppLockController controller;
  final Widget child;
  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool requestedBiometric = false;
  Future<void> resetPin() async {
    final navigator =
        widget.navigatorKey?.currentState ?? Navigator.maybeOf(context);
    if (navigator != null && await widget.controller.biometric() && mounted) {
      await navigator.push<void>(
        MaterialPageRoute(
          builder: (_) => PinSetupScreen(controller: widget.controller),
        ),
      );
    }
  }

  late final Timer timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.controller.locked) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      widget.controller.background();
    }
    if (state == AppLifecycleState.resumed) widget.controller.resumed();
  }

  @override
  void dispose() {
    timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final lock = widget.controller;
      final blocked = !lock.ready || lock.locked;
      if (!blocked) requestedBiometric = false;
      if (blocked &&
          lock.ready &&
          !lock.backgrounded &&
          lock.useBiometric &&
          !lock.busy &&
          !requestedBiometric) {
        requestedBiometric = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && lock.locked) unawaited(lock.biometric());
        });
      }
      return Overlay.wrap(
        child: PopScope(
          canPop: !blocked,
          child: Stack(
            children: [
              ExcludeFocus(
                excluding: blocked,
                child: Offstage(
                  offstage: blocked,
                  child: TickerMode(enabled: !blocked, child: widget.child),
                ),
              ),
              if (blocked)
                Positioned.fill(
                  child: Scaffold(
                    body: Stack(
                      children: [
                        Positioned.fill(
                          child: SafeArea(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: !lock.ready
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const ArtaLogo(size: 64),
                                          const SizedBox(height: 24),
                                          Text(
                                            lock.error ??
                                                'Menyiapkan keamanan…',
                                            textAlign: TextAlign.center,
                                          ),
                                          if (!lock.busy)
                                            TextButton(
                                              onPressed: lock.initialize,
                                              child: const Text('Coba lagi'),
                                            ),
                                        ],
                                      )
                                    : PinKeypad(
                                        fullPage: true,
                                        enabled: !lock.busy,
                                        error: lock.error,
                                        retrySeconds: lock.retrySeconds,
                                        onComplete: (pin) async {
                                          await lock.pin(pin);
                                        },
                                        onBiometric: lock.useBiometric
                                            ? lock.biometric
                                            : null,
                                        onForgot: lock.useBiometric
                                            ? resetPin
                                            : () => showModalBottomSheet<void>(
                                                context: context,
                                                useSafeArea: true,
                                                builder: (context) =>
                                                    const SafeArea(
                                                      top: false,
                                                      child: Padding(
                                                        padding: EdgeInsets.all(
                                                          24,
                                                        ),
                                                        child: Text(
                                                          'Reset PIN memerlukan sidik jari yang diaktifkan sebelumnya. Data dan PIN tidak dihapus saat verifikasi tidak tersedia.',
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (lock.busy)
                          Positioned.fill(
                            child: AbsorbPointer(
                              child: ColoredBox(
                                color: const Color(0x99000000),
                                child: const Center(
                                  child: ArtaLogo(loading: true, size: 56),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
