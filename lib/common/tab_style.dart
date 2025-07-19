import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';

const Color tabBackgroundColor = Color(0xFF252526);
const Color tabHoverColor = Color(0xFF2D2D2D);
const Color tabBorderColor = Color(0xFF474747);
const Color tabIndicatorColor = Color(0xFF4DB6AC);

const double tabHeight = 35.0;
const double tabTextSize = 13.0;

BoxDecoration getTabBarDecoration() {
  return const BoxDecoration(
    color: tabBackgroundColor,
    border: Border(bottom: BorderSide(color: tabBorderColor, width: 1)),
  );
}

BoxDecoration getTabDecoration({bool isSelected = false, bool isHovered = false, bool showTopBorder = true}) {
  return BoxDecoration(
    color: isSelected || isHovered ? tabHoverColor : tabBackgroundColor,
    border: Border(
      top:
          showTopBorder
              ? BorderSide(color: isSelected ? tabIndicatorColor : Colors.transparent, width: 1)
              : BorderSide.none,
      right: const BorderSide(color: tabBorderColor, width: 1),
    ),
  );
}

BoxDecoration getTabPlusDecoration({bool isSelected = false, bool isHovered = false, bool showTopBorder = true}) {
  return BoxDecoration(
    color: isSelected || isHovered ? tabHoverColor : tabBackgroundColor,
    border: Border(
      top:
          showTopBorder
              ? BorderSide(color: isSelected ? tabIndicatorColor : Colors.transparent, width: 1)
              : BorderSide.none,
    ),
  );
}

TextStyle get tabTextStyle => const TextStyle(color: lightTextColor, fontSize: tabTextSize);

const tabConstraints = BoxConstraints(minWidth: 125);
const tabPadding = EdgeInsets.symmetric(horizontal: 16);
