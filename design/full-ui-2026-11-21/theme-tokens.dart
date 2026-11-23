// Variables exported from FigCraft.

import 'dart:ui';

/// Theme · Dark
abstract final class Theme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF191919);
  static const Color surfaceRaised = Color(0xFF222222);
  static const Color surfaceInner = Color(0xFF161616);
  static const Color border = Color(0xFF2E2E2E);
  static const Color borderInput = Color(0xFF484848);
  static const Color textPrimary = Color(0xFFCBCBCB);
  static const Color textSecondary = Color(0xFF969696);
  static const Color textMuted = Color(0xFF828282);
  static const Color accent = Color(0xFF00AB6B);
  static const Color accentFill = Color(0xFF00AB6B);
  static const Color accentTint = Color(0xFF152E24);
  static const Color action = Color(0xFF008354);
  static const Color onAction = Color(0xFFFFFFFF);
  static const Color negative = Color(0xFFEF6363);
  static const Color negativeTint = Color(0xFF3B2020);
  static const Color purple = Color(0xFFA18CE8);
  static const Color purpleTint = Color(0xFF29233E);
  static const Color blue = Color(0xFF529CD7);
  static const Color blueTint = Color(0xFF192E3A);
  static const Color warning = Color(0xFFD7A64B);
  static const Color warningTint = Color(0xFF332A1B);
  static const Color scrim = Color(0x99000000);
  static const Color chartGrid = Color(0xFF303030);
  static const Color disabled = Color(0xFF414141);
  static const Color onDisabled = Color(0xFF8F8F8F);
  static const Color badgeNeutral = Color(0xFF303030);
  static const Color badgeGreen = Color(0xFF1E4336);
  static const Color badgePurple = Color(0xFF3B3455);
  static const Color badgeBlue = Color(0xFF234354);
  static const Color badgeRed = Color(0xFF5B2B2B);
}

/// Theme · Light
abstract final class ThemeLight {
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceRaised = Color(0xFFF7F7F7);
  static const Color surfaceInner = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFEDEDED);
  static const Color borderInput = Color(0xFFB5B5B5);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF707070);
  static const Color textMuted = Color(0xFF767676);
  static const Color accent = Color(0xFF00804F);
  static const Color accentFill = Color(0xFF00AB6B);
  static const Color accentTint = Color(0xFFEBF8F3);
  static const Color action = Color(0xFF008354);
  static const Color onAction = Color(0xFFFFFFFF);
  static const Color negative = Color(0xFFC83B3B);
  static const Color negativeTint = Color(0xFFFFF1F1);
  static const Color purple = Color(0xFF6B5BDC);
  static const Color purpleTint = Color(0xFFF2F1FE);
  static const Color blue = Color(0xFF1C6B98);
  static const Color blueTint = Color(0xFFEDF6FC);
  static const Color warning = Color(0xFF8A5D10);
  static const Color warningTint = Color(0xFFFFF7E6);
  static const Color scrim = Color(0x66000000);
  static const Color chartGrid = Color(0xFFE4E4E4);
  static const Color disabled = Color(0xFFE3E3E3);
  static const Color onDisabled = Color(0xFF777777);
  static const Color badgeNeutral = Color(0xFFEDEDED);
  static const Color badgeGreen = Color(0xFFCCEEE1);
  static const Color badgePurple = Color(0xFFE4E1FC);
  static const Color badgeBlue = Color(0xFFD2E9F9);
  static const Color badgeRed = Color(0xFFFFDADA);
}

/// IconTone · Neutral
abstract final class IconTone {
  static const Color iconStroke = Color(0xFF969696);
  static const Color iconTint = Color(0xFF303030);
}

/// IconTone · Green
abstract final class IconToneGreen {
  static const Color iconStroke = Color(0xFF00AB6B);
  static const Color iconTint = Color(0xFF1E4336);
}

/// IconTone · Purple
abstract final class IconTonePurple {
  static const Color iconStroke = Color(0xFFA18CE8);
  static const Color iconTint = Color(0xFF3B3455);
}

/// IconTone · Blue
abstract final class IconToneBlue {
  static const Color iconStroke = Color(0xFF529CD7);
  static const Color iconTint = Color(0xFF234354);
}

/// IconTone · Red
abstract final class IconToneRed {
  static const Color iconStroke = Color(0xFFEF6363);
  static const Color iconTint = Color(0xFF5B2B2B);
}

/// IconTone · Muted
abstract final class IconToneMuted {
  static const Color iconStroke = Color(0xFF828282);
  static const Color iconTint = Color(0xFF303030);
}
