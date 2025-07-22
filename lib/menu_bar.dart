import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/context_menu.dart';
import 'package:trayce/common/context_menu_style.dart';
import 'package:trayce/common/file_picker.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/settings.dart';

class AppMenuBar extends StatelessWidget {
  final Widget child;
  final String appVersion;
  final void Function(String path)? onFileOpen;
  final void Function(String path)? onFileSave;

  const AppMenuBar({super.key, required this.child, required this.appVersion, this.onFileOpen, this.onFileSave});

  Future<void> _handleOpen(BuildContext context) async {
    final path = await context.read<FilePicker>().openTrayceDB();

    if (path != null) {
      onFileOpen?.call(path);
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    final path = await context.read<FilePicker>().saveTrayceDB();

    if (path != null) {
      onFileSave?.call(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) {
      return PlatformMenuBar(
        menus: [
          PlatformMenu(
            label: 'File',
            menus: [
              PlatformMenuItem(
                label: 'Open',
                shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
                onSelected: () => _handleOpen(context),
              ),
              PlatformMenuItem(
                label: 'Save As',
                shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
                onSelected: () => _handleSave(context),
              ),
              PlatformMenuItem(label: 'Settings', onSelected: () => showSettingsModal(context)),
            ],
          ),
          PlatformMenu(
            label: 'Help',
            menus: [
              PlatformMenuItem(
                label: 'About',
                onSelected: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Trayce',
                    applicationVersion: appVersion,
                    applicationIcon: const Icon(Icons.track_changes),
                  );
                },
              ),
            ],
          ),
        ],
        child: child,
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: borderColor, width: 1))),
          child: MenuBar(
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Color(0xFF333333)),
              visualDensity: VisualDensity(horizontal: 0, vertical: -4),
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              elevation: WidgetStatePropertyAll(0),
            ),
            children: [
              SubmenuButton(
                style: menuButtonStyle,
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(contextMenuColor),
                  shape: WidgetStatePropertyAll(contextMenuShape),
                  elevation: WidgetStatePropertyAll(0),
                ),
                alignmentOffset: const Offset(0, 0),
                menuChildren: [
                  CustomPopupMenuItem(
                    onTap: () => _handleOpen(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Open', style: contextMenuTextStyle),
                        Text('Ctrl+O', style: contextMenuTextStyle),
                      ],
                    ),
                  ),
                  CustomPopupMenuItem(
                    onTap: () => _handleSave(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Save As', style: contextMenuTextStyle),
                        Text('Ctrl+S', style: contextMenuTextStyle),
                      ],
                    ),
                  ),
                  CustomPopupMenuItem(
                    onTap: () => showSettingsModal(context),
                    child: Text('Settings', style: contextMenuTextStyle),
                  ),
                ],
                child: const Text('File'),
              ),
              SubmenuButton(
                style: menuButtonStyle,
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll(contextMenuColor),
                  shape: WidgetStatePropertyAll(contextMenuShape),
                  elevation: WidgetStatePropertyAll(0),
                ),
                alignmentOffset: const Offset(0, 0),
                menuChildren: [
                  CustomPopupMenuItem(
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Trayce',
                        applicationVersion: appVersion,
                        applicationIcon: const Icon(Icons.track_changes),
                      );
                    },
                    child: Text('About', style: contextMenuTextStyle),
                  ),
                ],
                child: const Text('Help'),
              ),
            ],
          ),
        ),
      ),
      body: child,
    );
  }
}
