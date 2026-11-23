import 'package:material_ui/material_ui.dart';

class ArtaLogo extends StatefulWidget {
  const ArtaLogo({super.key, this.loading = false, this.size = 64});
  final bool loading;
  final double size;
  @override
  State<ArtaLogo> createState() => _ArtaLogoState();
}

class _ArtaLogoState extends State<ArtaLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 960),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(ArtaLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.loading && !MediaQuery.disableAnimationsOf(context)) {
      if (!animation.isAnimating) animation.repeat();
    } else {
      animation.stop();
    }
  }

  @override
  void dispose() {
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.loading ? 'Arta sedang memuat data' : 'Logo Arta',
    image: true,
    child: SizedBox(
      width: widget.size,
      height: widget.size * 72 / 88,
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, _) => CustomPaint(
          painter: _LogoPainter(
            color: Theme.of(context).colorScheme.primary,
            progress: animation.value,
            animate: widget.loading && !MediaQuery.disableAnimationsOf(context),
          ),
        ),
      ),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.color,
    required this.progress,
    required this.animate,
  });
  final Color color;
  final double progress;
  final bool animate;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 88, size.height / 72);
    final paths = [
      Path()
        ..moveTo(0, 72)
        ..lineTo(26, 10)
        ..quadraticBezierTo(30, 0, 38, 0)
        ..lineTo(50, 0)
        ..lineTo(20, 72)
        ..close(),
      Path()
        ..moveTo(45, 0)
        ..lineTo(58, 0)
        ..lineTo(88, 72)
        ..lineTo(67, 72)
        ..close(),
      Path()
        ..moveTo(24, 48)
        ..lineTo(63, 48)
        ..lineTo(70, 64)
        ..lineTo(17, 64)
        ..close(),
    ];
    for (var i = 0; i < paths.length; i++) {
      var opacity = 1.0;
      if (animate) {
        final phase = progress * 3;
        final current = phase.floor() % 3;
        final next = (current + 1) % 3;
        final blend = ((phase - phase.floor()) / 0.75).clamp(0.0, 1.0);
        opacity = i == current
            ? 1 - 0.82 * blend
            : i == next
            ? 0.18 + 0.82 * blend
            : 0.18;
      }
      canvas.drawPath(
        paths[i],
        Paint()..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.color != color || old.progress != progress || old.animate != animate;
}
