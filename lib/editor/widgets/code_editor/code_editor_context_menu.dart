import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';
import 'package:trayce/common/context_menu.dart';

import '../../../common/context_menu_style.dart';

class ContextMenuControllerImpl implements SelectionToolbarController {
  const ContextMenuControllerImpl();

  @override
  void hide(BuildContext context) {}

  @override
  void show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    Rect? renderRect,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
  }) {
    showMenu(
      popUpAnimationStyle: contextMenuAnimationStyle,
      context: context,
      position: RelativeRect.fromLTRB(
        anchors.primaryAnchor.dx,
        anchors.primaryAnchor.dy,
        anchors.primaryAnchor.dx,
        anchors.primaryAnchor.dy,
      ),
      color: contextMenuColor,
      shape: contextMenuShape,
      items: [
        CustomPopupMenuItem(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Copy', style: contextMenuTextStyle), Text('Ctrl+C', style: contextMenuTextStyle)],
          ),
          onTap: () {
            controller.copy();
          },
        ),
        CustomPopupMenuItem(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Cut', style: contextMenuTextStyle), Text('Ctrl+X', style: contextMenuTextStyle)],
          ),
          onTap: () {
            controller.cut();
          },
        ),
        CustomPopupMenuItem(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Paste', style: contextMenuTextStyle), Text('Ctrl+V', style: contextMenuTextStyle)],
          ),
          onTap: () {
            controller.paste();
          },
        ),
      ],
    );
  }
}
