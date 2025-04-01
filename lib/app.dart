import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trayce/common/database.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/menu_bar.dart';
import 'package:trayce/network/repo/proto_def_repo.dart';
import 'package:trayce/status_bar.dart';

import 'editor/editor.dart';
import 'network/repo/flow_repo.dart';
import 'network/widgets/network.dart';

const Color backgroundColor = Color(0xFF1E1E1E);
const Color textColor = Color(0xFFD4D4D4);
const Color sidebarColor = Color(0xFF333333);

class App extends StatelessWidget {
  final String appVersion;

  const App({
    super.key,
    required this.appVersion,
  });

  static final _navigatorKey = GlobalKey<NavigatorState>();

  // Helper function to create AppScaffold instances
  static Widget _createPage(int index) {
    return AppScaffold(
      selectedIndex: index,
      child: index == 0 ? const Network() : const Editor(),
    );
  }

  // Helper function to handle database operations
  static Future<void> _changeDatabase(BuildContext context, String path, {bool shouldCopy = false}) async {
    try {
      final flowRepo = context.read<FlowRepo>();
      final protoDefRepo = context.read<ProtoDefRepo>();
      final oldDb = flowRepo.db;
      if (oldDb.path == path) {
        return;
      }

      if (shouldCopy) {
        await File(oldDb.path).copy(path);
      }

      final newDb = await connectDB(path);
      flowRepo.db = newDb;
      protoDefRepo.db = newDb;
      await oldDb.close();

      if (context.mounted) {
        _navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => _createPage(0),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${shouldCopy ? 'saving' : 'opening'} database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trayce',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: Builder(
        builder: (context) => AppMenuBar(
          appVersion: appVersion,
          onFileOpen: (path) => _changeDatabase(context, path),
          onFileSave: (path) => _changeDatabase(context, path, shouldCopy: true),
          child: Scaffold(
            body: Navigator(
              key: _navigatorKey,
              onGenerateRoute: (settings) {
                Widget page;
                if (settings.name == '/editor') {
                  page = _createPage(1);
                } else {
                  page = _createPage(0);
                }
                return MaterialPageRoute(builder: (_) => page);
              },
            ),
            bottomNavigationBar: const StatusBar(),
          ),
        ),
      ),
    );
  }
}

class AppScaffold extends StatefulWidget {
  final Widget child;
  final int selectedIndex;

  const AppScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool isHovering0 = false;
  bool isHovering1 = false;

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/network');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/editor');
        break;
    }
  }

  BoxDecoration _getSidebarItemDecoration(bool isSelected, bool isHovering) {
    return BoxDecoration(
      border: Border(
        left: BorderSide(
          color: isSelected ? const Color(0xFF4DB6AC) : Colors.transparent,
          width: 2,
        ),
      ),
      color: isSelected || isHovering ? const Color(0xFF3A3A3A) : Colors.transparent,
    );
  }

  Widget _getSidebarItem(bool isHovering, bool isSelected, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _getSidebarItemDecoration(isSelected, isHovering),
      child: Icon(
        icon,
        color: textColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            color: sidebarColor,
            child: Column(
              children: [
                Listener(
                  onPointerDown: (_) => _navigateToPage(0),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => isHovering0 = true),
                    onExit: (_) => setState(() => isHovering0 = false),
                    child: _getSidebarItem(isHovering0, widget.selectedIndex == 0, Icons.format_list_numbered),
                  ),
                ),
                Listener(
                  onPointerDown: (_) => _navigateToPage(1),
                  child: MouseRegion(
                    onEnter: (_) => setState(() => isHovering1 = true),
                    onExit: (_) => setState(() => isHovering1 = false),
                    child: _getSidebarItem(isHovering1, widget.selectedIndex == 1, Icons.edit),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: Color(0xFF474747),
          ),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
