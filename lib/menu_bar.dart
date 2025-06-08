import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trayce/common/file_menu_style.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/settings.dart';

class AppMenuBar extends StatelessWidget {
  final Widget child;
  final String appVersion;
  final void Function(String path)? onFileOpen;
  final void Function(String path)? onFileSave;

  const AppMenuBar({super.key, required this.child, required this.appVersion, this.onFileOpen, this.onFileSave});

  Future<void> _handleOpen() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'trayce', extensions: <String>['db']);
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

    final path = file?.path;

    if (path != null) {
      onFileOpen?.call(path);
    }
  }

  Future<void> _handleSave() async {
    const XTypeGroup typeGroup = XTypeGroup(label: 'trayce', extensions: <String>['db']);
    final FileSaveLocation? file = await getSaveLocation(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

    final path = file?.path;

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
                onSelected: _handleOpen,
              ),
              PlatformMenuItem(
                label: 'Save As',
                shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
                onSelected: _handleSave,
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
                menuStyle: fileSubmenuStyle,
                alignmentOffset: const Offset(0, 0),
                menuChildren: [
                  MenuItemButton(
                    style: fileMenuItemStyle,
                    onPressed: _handleOpen,
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyO, control: true),
                    child: const Text('Open'),
                  ),
                  MenuItemButton(
                    style: fileMenuItemStyle,
                    onPressed: _handleSave,
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
                    child: const Text('Save As'),
                  ),
                  MenuItemButton(
                    style: fileMenuItemStyle,
                    onPressed: () => showSettingsModal(context),
                    child: const Text('Settings'),
                  ),
                ],
                child: const Text('File'),
              ),
              SubmenuButton(
                style: menuButtonStyle,
                menuStyle: fileSubmenuStyle,
                alignmentOffset: const Offset(0, 0),
                menuChildren: [
                  MenuItemButton(
                    style: fileMenuItemStyle,
                    onPressed: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Trayce',
                        applicationVersion: appVersion,
                        applicationIcon: const Icon(Icons.track_changes),
                      );
                    },
                    child: const Text('About'),
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
