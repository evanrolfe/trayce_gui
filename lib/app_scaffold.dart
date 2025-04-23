import 'package:flutter/material.dart';

const Color textColor = Color(0xFFD4D4D4);
const Color sidebarColor = Color(0xFF333333);

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

  void _navigateToPage(int index) {
    widget.onIndexChanged(index);
  }

  BoxDecoration _getSidebarItemDecoration(bool isSelected, bool isHovering) {
    return BoxDecoration(
      border: Border(left: BorderSide(color: isSelected ? const Color(0xFF4DB6AC) : Colors.transparent, width: 2)),
      color: isSelected || isHovering ? const Color(0xFF3A3A3A) : Colors.transparent,
    );
  }

  Widget _getSidebarItem(bool isHovering, bool isSelected, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getSidebarItemDecoration(isSelected, isHovering),
      child: Icon(icon, color: textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar:
          Container(
            color: sidebarColor,
            child: Column(
              children: [
                Listener(
                  onPointerDown: (_) => _navigateToPage(0),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => isHovering0 = true),
                    onExit: (_) => setState(() => isHovering0 = false),
                    child: _getSidebarItem(isHovering0, widget.selectedIndex == 0, Icons.format_list_numbered),
                  ),
                ),
                Listener(
                  onPointerDown: (_) => _navigateToPage(1),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => isHovering1 = true),
                    onExit: (_) => setState(() => isHovering1 = false),
                    child: _getSidebarItem(isHovering1, widget.selectedIndex == 1, Icons.edit),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFF474747)),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
