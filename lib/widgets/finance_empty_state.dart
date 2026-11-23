import 'arta_icon.dart';

import 'package:material_ui/material_ui.dart';
import 'package:feather_icons/feather_icons.dart';

enum EmptyKind { accounts, transactions, calendar, search, cards, receipt }

/// Small finance illustrations drawn locally, without network or bitmap assets.
class FinanceEmptyState extends StatelessWidget {
  const FinanceEmptyState({
    super.key,
    required this.message,
    this.kind = EmptyKind.transactions,
    this.compact = false,
  });
  final String message;
  final EmptyKind kind;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (kind) {
      EmptyKind.accounts => FeatherIcons.briefcase,
      EmptyKind.transactions => FeatherIcons.fileText,
      EmptyKind.receipt => FeatherIcons.image,
      EmptyKind.calendar => FeatherIcons.calendar,
      EmptyKind.search => FeatherIcons.search,
      EmptyKind.cards => FeatherIcons.creditCard,
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 16 : 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: compact ? 112 : 148,
              height: compact ? 90 : 116,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FinanceScene(
                        colors.primary,
                        colors.surface,
                        colors.outlineVariant,
                      ),
                    ),
                  ),
                  ArtaIcon(
                    icon,
                    size: compact ? 35 : 46,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceScene extends CustomPainter {
  const _FinanceScene(this.accent, this.surface, this.outline);
  final Color accent, surface, outline;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 148, size.height / 116);
    canvas.drawOval(
      const Rect.fromLTWH(4, 7, 140, 102),
      Paint()..color = accent.withValues(alpha: .055),
    );
    final rear = RRect.fromRectAndRadius(
      const Rect.fromLTWH(32, 20, 85, 76),
      const Radius.circular(15),
    );
    canvas.drawRRect(rear, Paint()..color = accent.withValues(alpha: .10));
    final front = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 13, 91, 82),
      const Radius.circular(15),
    );
    canvas.drawRRect(front, Paint()..color = surface);
    canvas.drawRRect(
      front,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final stroke = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(const Offset(119, 91), 13, Paint()..color = surface);
    canvas.drawCircle(const Offset(119, 91), 13, stroke);
    canvas.drawPath(
      Path()
        ..moveTo(113, 92)
        ..lineTo(117, 96)
        ..lineTo(125, 86),
      stroke,
    );
    canvas.drawCircle(
      const Offset(18, 96),
      3,
      Paint()..color = accent.withValues(alpha: .3),
    );
    canvas.drawCircle(
      const Offset(130, 23),
      4,
      Paint()..color = accent.withValues(alpha: .2),
    );
    canvas.drawLine(const Offset(8, 32), const Offset(15, 32), stroke);
    canvas.drawLine(const Offset(11.5, 28.5), const Offset(11.5, 35.5), stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FinanceScene old) =>
      old.accent != accent || old.surface != surface || old.outline != outline;
}
