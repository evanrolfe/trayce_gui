import 'package:flutter/material.dart';

import '../explorer/explorer_style.dart';

class InlineTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabTitles;
  final FocusNode? focusNode;
  final VoidCallback? onTabChanged;

  const InlineTabBar({super.key, required this.controller, required this.tabTitles, this.focusNode, this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      dividerColor: Colors.transparent,
      labelColor: const Color(0xFFD4D4D4),
      unselectedLabelColor: const Color(0xFF808080),
      indicator: const UnderlineTabIndicator(borderSide: BorderSide(width: 1, color: Color(0xFF4DB6AC))),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelStyle: const TextStyle(fontWeight: FontWeight.normal),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      tabs:
          tabTitles.asMap().entries.map((entry) {
            final index = entry.key;
            final title = entry.value;
            return GestureDetector(
              onTapDown: (_) {
                controller.animateTo(index);
                focusNode?.requestFocus();
                onTabChanged?.call();
              },
              child: Container(
                color: Colors.blue.withValues(alpha: 0.0),
                child: SizedBox(width: 100, child: Tab(text: title)),
              ),
            );
          }).toList(),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.hovered)) {
          return hoveredItemColor.withAlpha(hoverAlpha);
        }
        return null;
      }),
    );
  }
}
