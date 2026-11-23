import 'arta_icon.dart';

import 'package:material_ui/material_ui.dart';
import 'package:feather_icons/feather_icons.dart';

class FinanceIconBadge extends StatelessWidget {
  const FinanceIconBadge(this.icon, {super.key, this.color, this.size = 40});
  final IconData icon;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final purple =
        icon == FeatherIcons.trendingUp ||
        icon == FeatherIcons.activity ||
        icon == FeatherIcons.pieChart ||
        icon == FeatherIcons.barChart2;
    final ink = color ?? (purple ? colors.secondary : colors.primary);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ink.withValues(alpha: .16),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: ArtaIcon(icon, size: size * .47, color: ink),
    );
  }
}

class FinanceHero extends StatelessWidget {
  const FinanceHero({
    super.key,
    required this.label,
    required this.value,
    required this.details,
    this.footer,
    this.trailing,
  });
  final String label, value;
  final List<Widget> details;
  final Widget? footer, trailing;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colors.surface,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) => Text(
              value,
              style: theme.textTheme.headlineSmall,
              softWrap: true,
            ),
          ),
          const SizedBox(height: 18),
          ...details,
          if (footer != null) ...[
            const SizedBox(height: 16),
            Divider(color: colors.primary.withValues(alpha: .12)),
            const SizedBox(height: 12),
            footer!,
          ],
        ],
      ),
    );
  }
}

class FinanceFeatureTile extends StatelessWidget {
  const FinanceFeatureTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: ListTile(
        onTap: onTap,
        leading: FinanceIconBadge(icon, size: 38),
        title: Text(title, style: Theme.of(context).textTheme.labelLarge),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const ArtaIcon(FeatherIcons.chevronRight, size: 18),
      ),
    ),
  );
}
