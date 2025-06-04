import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      if (node.type == NodeType.request)
        PopupMenuItem(
          height: 30,
          child: Text('Open', style: contextMenuTextStyle),
          onTap: () => context.read<ExplorerRepo>().openNode(node),
        ),
      if (node.type == NodeType.collection)
        PopupMenuItem(
          height: 30,
          child: Text('Close Collection', style: contextMenuTextStyle),
          onTap: () => context.read<ExplorerRepo>().closeCollection(node),
        ),
      if (node.type == NodeType.folder)
        PopupMenuItem(
          height: 30,
          child: Text('New Request', style: contextMenuTextStyle),
          onTap: () => onNewRequestInFolder(node),
        ),
      PopupMenuItem(height: 30, child: Text('Rename', style: contextMenuTextStyle), onTap: () => onRename(node)),
      PopupMenuItem(height: 30, child: Text('Delete', style: contextMenuTextStyle), onTap: () => onDelete(node)),
    ],
  );
}
