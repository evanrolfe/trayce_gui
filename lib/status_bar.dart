import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/network/repo/containers_repo.dart';
import 'package:trayce/network/widgets/containers_modal.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({super.key});

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar> {
  bool _agentRunning = false;
  bool _isHovering = false;
  late final StreamSubscription _agentRunningSubscription;

  @override
  void initState() {
    super.initState();
    _agentRunningSubscription = context.read<EventBus>().on<EventAgentRunning>().listen((event) {
      setState(() {
        _agentRunning = event.running;
      });
    });
  }

  @override
  void dispose() {
    _agentRunningSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
        border: Border(
          top: BorderSide(
            color: Color(0xFF4DB6AC),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTap: () => showContainersModal(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _isHovering ? const Color(0xFF3A3A3A) : Colors.transparent,
                ),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFD4D4D4),
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.none,
                  ),
                  child: Text(
                    'Agent: ${_agentRunning ? 'running' : 'not running'}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
