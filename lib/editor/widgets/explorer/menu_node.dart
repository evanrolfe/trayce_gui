import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/context_menu.dart';
import 'package:trayce/common/context_menu_style.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/repo/explorer_service.dart';

void showNodeMenu(
  BuildContext context,
  TapDownDetails details,
  ExplorerNode node,
  Function(ExplorerNode) onRename,
  Function(ExplorerNode) onDelete,
  Function(ExplorerNode) onNewRequestInFolder,
  Function(ExplorerNode) onNewScriptInFolder,
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
      if (node is CollectionNode || node is FolderNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('New Request', style: contextMenuTextStyle), Text('Ctrl+N', style: contextMenuTextStyle)],
          ),
          onTap: () => onNewRequestInFolder(node),
        ),
      if (node is CollectionNode || node is FolderNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('New JS Script', style: contextMenuTextStyle)],
          ),
          onTap: () => onNewScriptInFolder(node),
        ),
      if (node is CollectionNode || node is FolderNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('New Folder', style: contextMenuTextStyle)],
          ),
          onTap: () => onNewFolder(node),
        ),
      if (node is CollectionNode || node is FolderNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Settings', style: contextMenuTextStyle)],
          ),
          onTap: () => onOpenNodeSettings(node),
        ),
      if (node is RequestNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          child: Text('Open', style: contextMenuTextStyle),
          onTap: () => context.read<ExplorerService>().openNode(node),
        ),
      if (node is RequestNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Copy', style: contextMenuTextStyle), Text('Ctrl+C', style: contextMenuTextStyle)],
          ),
          onTap: () => context.read<ExplorerService>().copyNode(node),
        ),
      if (node is FolderNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          enabled: context.read<ExplorerService>().canPaste(node),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('Paste', style: contextMenuTextStyle), Text('Ctrl+V', style: contextMenuTextStyle)],
          ),
          onTap: () => context.read<ExplorerService>().pasteNode(node),
        ),
      if (node is CollectionNode)
        CustomPopupMenuItem(
          height: 30,
          shouldPop: true,
          child: Text('Close Collection', style: contextMenuTextStyle),
          onTap: () => context.read<ExplorerService>().closeCollection(node),
        ),
      CustomPopupMenuItem(
        height: 30,
        shouldPop: true,
        child: Text('Rename', style: contextMenuTextStyle),
        onTap: () => onRename(node),
      ),
      CustomPopupMenuItem(
        height: 30,
        shouldPop: true,
        child: Text('Delete', style: contextMenuTextStyle),
        onTap: () => onDelete(node),
      ),
    ],
  );
}
