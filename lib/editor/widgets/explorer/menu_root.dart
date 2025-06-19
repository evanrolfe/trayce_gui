import 'dart:io';

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
  VoidCallback onRefresh,
) {
  int heightOffset = 0;
  if (Platform.isLinux) heightOffset = 32;

  final anchors = TextSelectionToolbarAnchors(
    primaryAnchor: Offset(width + 40, itemHeight),
  );
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
        child: Text('Open Collection', style: contextMenuTextStyle),
      ),
      CustomPopupMenuItem(
        height: 30,
        onTap: onNewCollection,
        child: Text('New Collection', style: contextMenuTextStyle),
      ),
      CustomPopupMenuItem(
        height: 30,
        onTap: onNewRequest,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('New Request', style: contextMenuTextStyle),
            Text('Ctrl+N', style: contextMenuTextStyle),
          ],
        ),
      ),
      CustomPopupMenuItem(
        height: 30,
        onTap: onRefresh,
        child: Text('Refresh', style: contextMenuTextStyle),
      ),
    ],
  );
}
