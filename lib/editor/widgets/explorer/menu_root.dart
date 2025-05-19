import 'package:flutter/material.dart';
import 'package:trayce/common/context_menu_style.dart';

void showRootMenu(
  BuildContext context,
  double width,
  double itemHeight,
  VoidCallback onOpenCollection,
  VoidCallback onNewRequest,
  VoidCallback onRefresh,
) {
  final anchors = TextSelectionToolbarAnchors(primaryAnchor: Offset(width + 40, itemHeight + 32));
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
        child: Text('Open Collection', style: contextMenuTextStyle),
        onTap: () => onOpenCollection(),
      ),
      PopupMenuItem(
        height: 30,
        child: Text('New Collection', style: contextMenuTextStyle),
        onTap: () {
          print('TODO: Implement New Collection');
        },
      ),
      PopupMenuItem(height: 30, onTap: () => onRefresh(), child: Text('Refresh', style: contextMenuTextStyle)),
      PopupMenuItem(height: 30, onTap: onNewRequest, child: Text('New Request', style: contextMenuTextStyle)),
    ],
  );
}
