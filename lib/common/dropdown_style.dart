import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/widgets/explorer/explorer_style.dart';

final dropdownDecoration = BoxDecoration(
  color: inputBackgroundColor,
  border: Border.all(color: borderColor),
  borderRadius: BorderRadius.circular(2),
);
final buttonStyleData = const ButtonStyleData(height: 22, padding: EdgeInsets.symmetric(horizontal: 4));
final menuItemStyleData = MenuItemStyleData(
  height: 24,
  padding: EdgeInsets.zero,
  overlayColor: WidgetStateProperty.all(selectedMenuItemColor),
);
final iconStyleData = const IconStyleData(
  icon: Icon(Icons.arrow_drop_down, size: 16),
  iconEnabledColor: lightTextColor,
);

final methodDropdownDecoration = BoxDecoration(
  color: inputBackgroundColor,
  border: Border(
    top: BorderSide(color: const Color(0xFF474747), width: 1),
    left: BorderSide(color: const Color(0xFF474747), width: 1),
    bottom: BorderSide(color: const Color(0xFF474747), width: 1),
  ),
  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
);
