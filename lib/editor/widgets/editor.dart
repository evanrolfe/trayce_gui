import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/common/dialog.dart';
import 'package:trayce/network/repo/containers_repo.dart';

import 'editor_tabs.dart';
import 'explorer/explorer.dart';
import 'explorer/explorer_style.dart';

class EditorCache {
  static double? _cachedWidth;

  static Future<void> preloadWidth() async {
    if (_cachedWidth != null) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedWidth = prefs.getDouble(leftPaneWidthKey);
  }

  static double get width => _cachedWidth ?? -1;

  static Future<void> saveWidth(double width) async {
    _cachedWidth = width;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(leftPaneWidthKey, width);
  }
}

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final ValueNotifier<double> _widthNotifier;
  bool isDividerHovered = false;
  bool _isLicenseDialogShowing = false;
  late final StreamSubscription _licenseSub;

  @override
  void initState() {
    super.initState();
    _widthNotifier = ValueNotifier(EditorCache.width);
    EditorCache.preloadWidth().then((_) {
      _widthNotifier.value = EditorCache.width;
    });

    _licenseSub = context.read<EventBus>().on<EventLicenseRequired>().listen((event) {
      if (!mounted) return;
      if (_isLicenseDialogShowing) return;

      _isLicenseDialogShowing = true;
      showLicenseDialog(context: context).then((value) {
        _isLicenseDialogShowing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _widthNotifier,
      builder: (context, leftPaneWidth, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final effectiveWidth = leftPaneWidth < 0 ? (defaultPaneWidth / totalWidth).clamp(0.0, 1.0) : leftPaneWidth;

            return Stack(
              children: [
                Row(
                  children: [
                    FileExplorer(width: totalWidth * effectiveWidth),
                    EditorTabs(width: totalWidth * (1 - effectiveWidth)),
                  ],
                ),
                Positioned(
                  left: totalWidth * effectiveWidth - 1.5,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    onEnter: (_) => setState(() => isDividerHovered = true),
                    onExit: (_) => setState(() => isDividerHovered = false),
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final localPosition = box.globalToLocal(details.globalPosition);
                        final newLeftWidth = localPosition.dx / totalWidth;

                        // Check if the new widths would be valid
                        final newRightWidth = 1 - newLeftWidth;
                        if ((newLeftWidth * totalWidth) >= minPaneWidth &&
                            (newRightWidth * totalWidth) >= minPaneWidth) {
                          _saveWidth(newLeftWidth);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(width: 3, color: Colors.transparent),
                          Positioned(
                            left: 1,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 1,
                              color: isDividerHovered ? const Color(0xFF4DB6AC) : const Color(0xFF474747),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveWidth(double width) async {
    await EditorCache.saveWidth(width);
    _widthNotifier.value = width;
  }

  @override
  void dispose() {
    _widthNotifier.dispose();
    _licenseSub.cancel();
    super.dispose();
  }
}
