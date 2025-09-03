import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/network/repo/containers_repo.dart';
import 'package:trayce/network/widgets/containers_modal.dart';
import 'package:trayce/settings.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  bool _agentRunning = false;
  bool _isHovering = false;
  bool _isDonateHovering = false;
  late final StreamSubscription _eventSub1;
  @override
  void initState() {
    super.initState();
    _eventSub1 = context.read<EventBus>().on<EventAgentRunning>().listen((event) {
      setState(() {
        _agentRunning = event.running;
      });
    });
  }

  @override
  void dispose() {
    _eventSub1.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: const BoxDecoration(
        color: statusBarBackground,
        border: Border(top: BorderSide(color: highlightBorderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isDonateHovering = true),
            onExit: (_) => setState(() => _isDonateHovering = false),
            child: GestureDetector(
              onTap: () => showSettingsModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: _isDonateHovering ? statusBarHoverBackground : Colors.transparent),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 12,
                    color: statusBarText,
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none,
                  ),
                  child: _buildDonateStatus(),
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: () => showContainersModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                decoration: BoxDecoration(color: _isHovering ? statusBarHoverBackground : Colors.transparent),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 12,
                    color: statusBarText,
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none,
                  ),
                  child: Text('Agent: ${_agentRunning ? 'running' : 'not running'}'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonateStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite, size: 18, color: Colors.red),
        const SizedBox(width: 2),
        const Text('Donate', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(width: 8),
      ],
    );
  }
}
