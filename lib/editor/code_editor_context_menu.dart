import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import '../common/context_menu_style.dart';

class ContextMenuItemWidget extends PopupMenuItem<void> implements PreferredSizeWidget {
  ContextMenuItemWidget({Key? key, required String text, required VoidCallback onTap})
    : super(key: key, onTap: onTap, child: Text(text));

  @override
  Size get preferredSize => const Size(150, 25);
}

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
