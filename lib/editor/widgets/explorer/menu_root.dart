import 'package:flutter/material.dart';
import 'package:trayce/common/context_menu.dart';
import 'package:trayce/common/context_menu_style.dart';

void showRootMenu(
  BuildContext context,
  double width,
  double itemHeight,
  VoidCallback onOpenCollection,
  VoidCallback onNewCollection,
  VoidCallback onNewRequest,
  VoidCallback onNewScript,
  VoidCallback onRefresh,
) {
  final anchors = TextSelectionToolbarAnchors(primaryAnchor: Offset(width + 40, itemHeight));
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
      CustomPopupMenuItem(
        height: 30,
        onTap: onOpenCollection,
        shouldPop: true,
        child: Text('Open Collection', style: contextMenuTextStyle),
      ),
      CustomPopupMenuItem(
        height: 30,
        onTap: onNewCollection,
        shouldPop: true,
        child: Text('New Collection', style: contextMenuTextStyle),
      ),
      CustomPopupMenuItem(
        height: 30,
        onTap: onNewRequest,
        shouldPop: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('New Request', style: contextMenuTextStyle), Text('Ctrl+N', style: contextMenuTextStyle)],
        ),
      ),
      CustomPopupMenuItem(
        height: 30,
        onTap: onNewScript,
        shouldPop: true,
        child: Text('New JS Script', style: contextMenuTextStyle),
      ),
      CustomPopupMenuItem(
        height: 30,
        onTap: onRefresh,
        shouldPop: true,
        child: Text('Refresh', style: contextMenuTextStyle),
      ),
    ],
  );
}
