import 'package:flutter/material.dart';
import 'package:trayce/common/context_menu_style.dart';
import 'package:trayce/common/style.dart';

final fileMenuItemStyle = MenuItemButton.styleFrom(
  backgroundColor: contextMenuColor,
  foregroundColor: lightTextColor,
  textStyle: contextMenuTextStyle,
  padding: const EdgeInsets.symmetric(horizontal: 10),
  minimumSize: const Size(175, 30),
  visualDensity: const VisualDensity(horizontal: 0, vertical: 0),
);

final fileSubmenuStyle = MenuStyle(
  backgroundColor: WidgetStatePropertyAll(contextMenuColor),
  shape: WidgetStatePropertyAll(contextMenuShape),
  padding: const WidgetStatePropertyAll(EdgeInsets.zero),
);
