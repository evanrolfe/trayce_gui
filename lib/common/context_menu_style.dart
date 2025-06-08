import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';

final contextMenuAnimationStyle = AnimationStyle(duration: Duration(seconds: 0));
final contextMenuColor = lightBackgroundColor;
final contextMenuShape = RoundedRectangleBorder(
  side: BorderSide(color: borderColor, width: 0.0),
  borderRadius: BorderRadius.all(Radius.circular(2)),
);
final contextMenuTextStyle = TextStyle(color: lightTextColor, fontWeight: FontWeight.normal, fontSize: 13);
