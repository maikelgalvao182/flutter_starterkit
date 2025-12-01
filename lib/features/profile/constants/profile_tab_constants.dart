import 'package:flutter/material.dart';

/// Constantes específicas do ProfileTab para evitar magic numbers
class ProfileTabConstants {
  ProfileTabConstants._();

  // Sizes
  static const double avatarContainerSize = 100;
  static const double avatarSize = 88; // 100 - 12 (padding)
  static const double chipHeight = 31;
  static const double iconSize = 24;
  static const double iconButtonSize = 28;
  static const double chipIconSize = 16;
  static const double cardHeight = 0.10; // MediaQuery height percentage

  // Paddings
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(20, 8, 20, 0);
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(20, 20, 20, 0);
  static const EdgeInsets cardContentPadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: 15);
  static const EdgeInsets chipSmallPadding = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 12);
  static const EdgeInsets iconButtonConstraints = EdgeInsets.zero;

  // Border Radius
  static const BorderRadius avatarBorderRadius = BorderRadius.all(Radius.circular(10));
  static const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(18));
  static const BorderRadius chipBorderRadius = BorderRadius.all(Radius.circular(30));

  // Spacing
  static const double smallSpacing = 4;
  static const double mediumSpacing = 8;
  static const double largeSpacing = 16;
  static const double extraLargeSpacing = 25;
  static const double headerSpacing = 10;
  static const double chipSpacing = 6;

  // Font Sizes
  static const double titleFontSize = 20;
  static const double cardTitleFontSize = 16;
  static const double cardSubtitleFontSize = 14;
  static const double buttonFontSize = 14;
  static const double chipFontSize = 12;

  // Box Constraints
  static const BoxConstraints iconButtonConstraintsBox = BoxConstraints();

  // Text Styles
  static const TextOverflow defaultTextOverflow = TextOverflow.ellipsis;
  static const int singleLineMaxLines = 1;
}