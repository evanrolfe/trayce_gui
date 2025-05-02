import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

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
      position: RelativeRect.fromSize(
        anchors.primaryAnchor & const Size(150, double.infinity),
        MediaQuery.of(context).size,
      ),
      color: contextMenuColor,
      shape: contextMenuShape,
      items: [
        PopupMenuItem(
          height: 30,
          child: Text('Copy', style: contextMenuTextStyle),
          onTap: () {
            controller.copy();
          },
        ),
        PopupMenuItem(
          height: 30,
          child: Text('Cut', style: contextMenuTextStyle),
          onTap: () {
            controller.cut();
          },
        ),
        PopupMenuItem(
          height: 30,
          child: Text('Paste', style: contextMenuTextStyle),
          onTap: () {
            controller.paste();
          },
        ),
      ],
    );
  }
}
