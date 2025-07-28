import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';

const Color textColor = Color(0xFFD4D4D4);
const Color sidebarColor = Color(0xFF333333);
const Color hoverColor = Color(0xFF3A3A3A);

class AppScaffold extends StatefulWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const AppScaffold({super.key, required this.child, required this.selectedIndex, required this.onIndexChanged});

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool isHovering0 = false;
  bool isHovering1 = false;
  bool showTooltip0 = false;
  bool showTooltip1 = false;
  Timer? _timer0;
  Timer? _timer1;

  @override
  void dispose() {
    _timer0?.cancel();
    _timer1?.cancel();
    super.dispose();
  }

  void _navigateToPage(int index) {
    widget.onIndexChanged(index);
  }

  BoxDecoration _getSidebarItemDecoration(bool isSelected, bool isHovering) {
    return BoxDecoration(
      border: Border(left: BorderSide(color: isSelected ? const Color(0xFF4DB6AC) : Colors.transparent, width: 2)),
      color: isSelected || isHovering ? const Color(0xFF3A3A3A) : Colors.transparent,
    );
  }

  Widget _getSidebarItem(Key key, bool isHovering, bool isSelected, IconData icon) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: _getSidebarItemDecoration(isSelected, isHovering),
      child: Icon(icon, color: textColor),
    );
  }

  static const _kFontFam = 'MyFlutterApp';
  static const String? _kFontPkg = null;
  static const IconData docker = IconData(0xf395, fontFamily: _kFontFam, fontPackage: _kFontPkg);

  Widget _buildTooltip(String text, double top, double left) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        height: 24,
        width: 120,
        decoration: BoxDecoration(
          color: hoverColor,
          borderRadius: BorderRadius.all(Radius.circular(4)),
          border: Border.all(color: highlightBorderColor, width: 1),
          //   border: Border.all(width: 0),
        ),
        child: Center(child: Text(text, style: const TextStyle(color: textColor, fontSize: 13))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // Sidebar:
              Container(
                color: sidebarColor,
                child: Column(
                  children: [
                    Listener(
                      onPointerDown: (_) => _navigateToPage(0),
                      child: MouseRegion(
                        onEnter: (_) {
                          setState(() => isHovering0 = true);
                          _timer1?.cancel();
                          _timer1 = Timer(const Duration(milliseconds: 500), () {
                            if (mounted && isHovering0) {
                              setState(() => showTooltip0 = true);
                            }
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            isHovering0 = false;
                            showTooltip0 = false;
                          });
                          _timer1?.cancel();
                        },
                        child: _getSidebarItem(
                          Key('editor-sidebar-btn'),
                          isHovering0,
                          widget.selectedIndex == 0,
                          Icons.edit,
                        ),
                      ),
                    ),
                    Listener(
                      onPointerDown: (_) => _navigateToPage(1),
                      child: MouseRegion(
                        onEnter: (_) {
                          setState(() => isHovering1 = true);
                          _timer0?.cancel();
                          _timer0 = Timer(const Duration(milliseconds: 500), () {
                            if (mounted && isHovering1) {
                              setState(() => showTooltip1 = true);
                            }
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            isHovering1 = false;
                            showTooltip1 = false;
                          });
                          _timer0?.cancel();
                        },
                        child: _getSidebarItem(
                          Key('network-sidebar-btn'),
                          isHovering1,
                          widget.selectedIndex == 1,
                          docker,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF474747)),
              Expanded(child: widget.child),
            ],
          ),
          if (showTooltip0) _buildTooltip('Editor', 20, 60),
          if (showTooltip1) _buildTooltip('Docker Network', 70, 60),
        ],
      ),
    );
  }
}
