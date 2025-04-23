import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';

final dropdownDecoration = BoxDecoration(
  color: lightBackgroundColor,
  border: Border.all(color: borderColor),
  borderRadius: BorderRadius.circular(2),
);
final buttonStyleData = const ButtonStyleData(height: 22, padding: EdgeInsets.symmetric(horizontal: 4));
final menuItemStyleData = MenuItemStyleData(height: 24, padding: EdgeInsets.zero);
final iconStyleData = const IconStyleData(
  icon: Icon(Icons.arrow_drop_down, size: 16),
  iconEnabledColor: lightTextColor,
);
