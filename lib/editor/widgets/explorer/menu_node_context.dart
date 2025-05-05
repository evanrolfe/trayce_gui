import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/context_menu_style.dart';
import 'package:trayce/editor/models/explorer_node.dart';
import 'package:trayce/editor/repo/explorer_repo.dart';

void showNodeContextMenu(BuildContext context, TapDownDetails details, ExplorerNode node) {
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
      PopupMenuItem(
        height: 30,
        child: Text('Rename', style: contextMenuTextStyle),
        onTap: () {
          // TODO: Implement rename functionality
          print('Rename ${node.name}');
        },
      ),
      PopupMenuItem(
        height: 30,
        child: Text('Delete', style: contextMenuTextStyle),
        onTap: () {
          // TODO: Implement delete functionality
          print('Delete ${node.name}');
        },
      ),
    ],
  );
}
