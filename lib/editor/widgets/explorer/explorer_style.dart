import 'package:flutter/material.dart';

// Dimensions
const double minPaneWidth = 200.0;
const double defaultPaneWidth = 250.0;
const double fileTreeLeftMargin = 10.0;
const double itemHeight = 25.0;
const double iconSize = 16.0;
const double fontSize = 13.0;

// Colors
const Color textColor = Color(0xFFD4D4D4);
const Color headerBackgroundColor = Color(0xFF333333);
const Color borderColorExplorer = Color(0xFF474747);
const Color fileIconColor = Color.fromARGB(255, 143, 143, 143);
const Color selectedItemColor = Color(0xFF2C4C49);
const Color hoveredItemColor = Color(0xFF2D2D2D);
const Color dropTargetColor = Colors.teal;
const int hoverAlpha = 77;

// Keys
const String leftPaneWidthKey = 'editor_left_pane_width';

// Text Styles
const TextStyle itemTextStyle = TextStyle(color: textColor, fontSize: fontSize);

// Borders
const Border headerBorder = Border(
  top: BorderSide(color: borderColorExplorer, width: 1),
  bottom: BorderSide(color: borderColorExplorer, width: 1),
);

// Decorations
const BoxDecoration headerDecoration = BoxDecoration(color: headerBackgroundColor, border: headerBorder);

BoxDecoration getItemDecoration({bool isHovered = false, bool isSelected = false, bool isDragTarget = false}) {
  return BoxDecoration(
    color:
        isDragTarget
            ? dropTargetColor.withAlpha(hoverAlpha)
            : isSelected
            ? selectedItemColor
            : isHovered
            ? hoveredItemColor.withAlpha(hoverAlpha)
            : null,
  );
}

const BoxDecoration transparentDecoration = BoxDecoration(color: Colors.transparent);
