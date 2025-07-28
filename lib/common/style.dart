import 'package:flutter/material.dart';

const Color inputBackgroundColor = Color(0xFF1B1B1C);
const Color textColor = Color(0xFF1E1E1E);
const Color lightTextColor = Color(0xFFD4D4D4);
const Color backgroundColor = Color(0xFF1E1E1E);
const Color lightBackgroundColor = Color(0xFF252526);
const Color sidebarColor = Color(0xFF333333);
const Color borderColor = Color(0xFF474747);
const Color lightButtonColor = Color(0xFF2C2C2C);
const Color selectedItemColor = Color(0xFF65AE7F);

const Color highlightBorderColor = Color(0xFF4DB6AC);
const Color fadedHighlightBorderColor = Color(0xFF2C4C49);
const Color statusBarBackground = Color(0xFF333333);
const Color statusBarText = Color(0xFFD4D4D4);
const Color statusBarHoverBackground = Color.fromARGB(255, 71, 71, 71);

const Color statusProtocolColor = Colors.grey;
const Color statusOkColor = Color.fromARGB(255, 67, 153, 69);
const Color statusWarningColor = Color.fromARGB(255, 235, 158, 44);
const Color statusErrorColor = Color.fromARGB(255, 209, 57, 46);

final commonButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: inputBackgroundColor,
  foregroundColor: lightTextColor,
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(4),
    side: BorderSide(color: lightTextColor.withOpacity(0.3)),
  ),
);

final commonButtonStyleBright = ElevatedButton.styleFrom(
  backgroundColor: Color(0xFF4DB6AC),
  padding: EdgeInsets.symmetric(horizontal: 16),
  minimumSize: Size(0, 36),
  maximumSize: Size(double.infinity, 36),
  textStyle: TextStyle(fontSize: 13, color: textColor),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
  foregroundColor: textColor,
);

final tabbarButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: lightButtonColor,
  padding: EdgeInsets.symmetric(horizontal: 16),
  minimumSize: Size(0, 30),
  maximumSize: Size(double.infinity, 36),
  textStyle: TextStyle(fontSize: 13, color: textColor),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: borderColor, width: 1)),
  foregroundColor: lightTextColor,
);

const textFieldStyle = TextStyle(color: lightTextColor, fontSize: 13);

const textFieldDecor = InputDecoration(
  border: OutlineInputBorder(borderSide: BorderSide(color: borderColor, width: 1)),
  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF4DB6AC), width: 1.0)),
  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor, width: 1)),
  hintStyle: TextStyle(color: Color(0xFF808080), fontSize: 13),
  filled: true,
  fillColor: inputBackgroundColor,
  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 11),
  constraints: BoxConstraints(maxHeight: 30, minHeight: 30),
);

const textFieldDecorReadOnly = InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  border: OutlineInputBorder(borderSide: BorderSide(color: borderColor, width: 1)),
  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor, width: 1.0)),
  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: borderColor, width: 1)),
  filled: true,
  fillColor: Color(0xFF2D2D2D),
);

const menuItemStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll(lightTextColor),
  backgroundColor: WidgetStatePropertyAll(Color(0xFF333333)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
  minimumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
  maximumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
);

const menuButtonStyle = ButtonStyle(
  foregroundColor: WidgetStatePropertyAll(Color(0xFFD4D4D4)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
  minimumSize: WidgetStatePropertyAll(Size(0, 40)),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
);

const menuStyle = MenuStyle(
  backgroundColor: WidgetStatePropertyAll(Color(0xFF252526)),
  padding: WidgetStatePropertyAll(EdgeInsets.zero),
  alignment: AlignmentDirectional.topStart,
);

var appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
  useMaterial3: true,
  scaffoldBackgroundColor: backgroundColor,
  scrollbarTheme: ScrollbarThemeData(
    thumbColor: WidgetStateProperty.all(Colors.teal),
    thickness: WidgetStateProperty.all(8),
    radius: const Radius.circular(4),
  ),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: sidebarColor,
    indicatorColor: Colors.teal,
    unselectedIconTheme: IconThemeData(color: textColor),
    selectedIconTheme: IconThemeData(color: textColor),
    unselectedLabelTextStyle: TextStyle(color: textColor),
    selectedLabelTextStyle: TextStyle(color: textColor),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.windows: NoTransitionBuilder(),
      TargetPlatform.linux: NoTransitionBuilder(),
      TargetPlatform.macOS: NoTransitionBuilder(),
    },
  ),
);

class NoTransitionBuilder extends PageTransitionsBuilder {
  const NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

// Dialog style
final dialogShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(3),
  side: const BorderSide(color: borderColor, width: 1),
);
