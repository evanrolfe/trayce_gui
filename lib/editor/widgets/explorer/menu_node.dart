import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/context_menu.dart';
import 'package:trayce/common/context_menu_style.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';

void showNodeMenu(
  BuildContext context,
  TapDownDetails details,
  ExplorerNode node,
  Function(ExplorerNode) onRename,
  Function(ExplorerNode) onDelete,
  Function(ExplorerNode) onNewRequestInFolder,
  Function(ExplorerNode) onNewFolder,
  Function(ExplorerNode) onOpenNodeSettings,
) {
  showMenu(
    popUpAnimationStyle: contextMenuAnimationStyle,
    context: context,
    position: RelativeRect.fromSize(
      details.globalPosition & const Size(150, double.infinity),
      MediaQuery.of(context).size,
    ),
    color: contextMenuColor,
    shape: contextMenuShape,
    items: [
      if (node.type == NodeType.collection || node.type == NodeType.folder)
        CustomPopupMenuItem(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('New Request', style: contextMenuTextStyle), Text('Ctrl+N', style: contextMenuTextStyle)],
          ),
          onTap: () => onNewRequestInFolder(node),
        ),
      if (node.type == NodeType.collection || node.type == NodeType.folder)
        CustomPopupMenuItem(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('New Folder', style: contextMenuTextStyle)],
          ),
          onTap: () => onNewFolder(node),
        ),
      if (node.type == NodeType.collection || node.type == NodeType.folder)
        CustomPopupMenuItem(
          height: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Settings', style: contextMenuTextStyle)],
          ),
          onTap: () => onOpenNodeSettings(node),
        ),
      if (node.type == NodeType.request)
        CustomPopupMenuItem(
          height: 30,
          child: Text('Open', style: contextMenuTextStyle),
          onTap: () => context.read<ExplorerRepo>().openNode(node),
        ),
      if (node.type == NodeType.collection)
        CustomPopupMenuItem(
          height: 30,
          child: Text('Close Collection', style: contextMenuTextStyle),
          onTap: () => context.read<ExplorerRepo>().closeCollection(node),
        ),
      CustomPopupMenuItem(height: 30, child: Text('Rename', style: contextMenuTextStyle), onTap: () => onRename(node)),
      CustomPopupMenuItem(height: 30, child: Text('Delete', style: contextMenuTextStyle), onTap: () => onDelete(node)),
    ],
  );
}
