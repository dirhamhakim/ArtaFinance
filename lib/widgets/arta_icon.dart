import 'package:feather_icons/feather_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// The editable FigCraft masters, bundled locally for both themes.
class ArtaIcon extends StatelessWidget {
  const ArtaIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });
  final IconData? icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  static final Map<IconData, String> glyphs = {
    FeatherIcons.home: 'home',
    FeatherIcons.grid: 'home',
    FeatherIcons.briefcase: 'portfolio',
    FeatherIcons.trendingUp: 'stocks',
    FeatherIcons.barChart2: 'stocks',
    FeatherIcons.activity: 'stocks',
    FeatherIcons.pieChart: 'portfolio',
    FeatherIcons.settings: 'settings',
    FeatherIcons.sliders: 'filter',
    FeatherIcons.filter: 'filter',
    FeatherIcons.fileText: 'receipt',
    FeatherIcons.creditCard: 'card',
    FeatherIcons.dollarSign: 'cash',
    FeatherIcons.repeat: 'transfer',
    FeatherIcons.layers: 'staking',
    FeatherIcons.percent: 'interest',
    FeatherIcons.lock: 'lock',
    FeatherIcons.unlock: 'unlock',
    FeatherIcons.eye: 'eye',
    FeatherIcons.eyeOff: 'eye-off',
    FeatherIcons.calendar: 'calendar',
    FeatherIcons.clock: 'clock',
    FeatherIcons.search: 'search',
    FeatherIcons.plus: 'plus',
    FeatherIcons.arrowDownLeft: 'arrow-down',
    FeatherIcons.arrowUpRight: 'arrow-up',
    FeatherIcons.arrowDown: 'import',
    FeatherIcons.arrowUp: 'export',
    FeatherIcons.download: 'export',
    FeatherIcons.upload: 'import',
    FeatherIcons.refreshCw: 'refresh',
    FeatherIcons.rotateCcw: 'history',
    FeatherIcons.chevronRight: 'chevron-right',
    FeatherIcons.chevronLeft: 'chevron-left',
    FeatherIcons.chevronDown: 'chevron-down',
    FeatherIcons.trash2: 'trash',
    FeatherIcons.delete: 'backspace',
    FeatherIcons.x: 'close',
    FeatherIcons.check: 'check',
    FeatherIcons.info: 'info',
    FeatherIcons.alertCircle: 'warning',
    FeatherIcons.alertTriangle: 'warning',
    FeatherIcons.copy: 'copy',
    FeatherIcons.paperclip: 'paperclip',
    FeatherIcons.image: 'paperclip',
    FeatherIcons.database: 'document',
    FeatherIcons.moon: 'moon',
    FeatherIcons.moreHorizontal: 'more',
    FeatherIcons.moreVertical: 'more',
    FeatherIcons.logOut: 'logout',
    FeatherIcons.bell: 'bell',
    Icons.fingerprint: 'fingerprint',
  };

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final asset = icon == null ? null : glyphs[icon];
    if (asset == null) {
      return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
    }
    return SvgPicture.asset(
      'assets/ui/icons/$asset.svg',
      width: size ?? theme.size ?? 24,
      height: size ?? theme.size ?? 24,
      colorFilter: ColorFilter.mode(
        color ?? theme.color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        BlendMode.srcIn,
      ),
      semanticsLabel: semanticLabel,
    );
  }
}

class DesignGlyph extends StatelessWidget {
  const DesignGlyph(this.name, {super.key, this.size = 24, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/ui/icons/$name.svg',
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(
      color ??
          IconTheme.of(context).color ??
          Theme.of(context).colorScheme.onSurfaceVariant,
      BlendMode.srcIn,
    ),
  );
}
