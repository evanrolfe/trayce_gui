import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/common/widgets/hoverable_icon_button.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showSettingsModal(BuildContext context) {
  return showDialog(context: context, builder: (dialogContext) => const SettingsModal());
}

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  late final TextEditingController _npmCommandController;
  late final TextEditingController _agentPortController;
  late final ConfigRepo _configRepo;

  // Tab management
  int _selectedTabIndex = 0;
  int? _hoveredTabIndex;

  // Tab items
  final List<String> _tabItems = ['Donate', 'Editor', 'Network'];

  @override
  void initState() {
    super.initState();

    _configRepo = context.read<ConfigRepo>();
    _npmCommandController = TextEditingController();
    _agentPortController = TextEditingController();

    _loadSettings();
  }

  void _loadSettings() {
    final config = _configRepo.get();
    _npmCommandController.text = config.npmCommand;
    _agentPortController.text = config.agentPort.toString();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onSave() {
    final config = _configRepo.get();
    config.npmCommand = _npmCommandController.text;
    config.agentPort = int.parse(_agentPortController.text);
    _configRepo.save();

    Navigator.of(context).pop();
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Donate
        return _buildDonateContent();
      case 1: // Editor
        return _buildEditorContent();
      case 2: // Network
        return _buildNetworkContent();
      default:
        return _buildDonateContent();
    }
  }

  Widget _buildDonateContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16),
          child: Text(
            'Donate',
            style: const TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText.rich(
                TextSpan(
                  text: 'Help support Trayce by donating to me on Github Sponsors:\n',
                  style: TextStyle(color: lightTextColor, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'https://github.com/sponsors/evanrolfe',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 14),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () async {
                              final url = Uri.parse('https://github.com/sponsors/evanrolfe');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditorContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16),
          child: Text(
            'Editor',
            style: const TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'NodeJS npm command:',
                              style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Enter the command to run npm (only necessary if you want to run scripts)',
                              child: const Icon(Icons.help_outline, color: Color(0xFF666666), size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 300,
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        key: const Key('editor_nodejs_command_input'),
                        controller: _npmCommandController,
                        style: textFieldStyle,
                        decoration: textFieldDecor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16),
          child: Text(
            'Network',
            style: const TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Agent port:',
                              style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'The port on which Trayce GUI will communicate with the Trayce Docker agent',
                              child: const Icon(Icons.help_outline, color: Color(0xFF666666), size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 300,
                    child: SizedBox(
                      height: 30,
                      child: TextField(
                        key: const Key('network_agent_port_input'),
                        controller: _agentPortController,
                        style: textFieldStyle,
                        decoration: textFieldDecor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: lightBackgroundColor,
      shape: dialogShape,
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Settings',
                    style: const TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  HoverableIconButton(onPressed: () => Navigator.of(context).pop(), icon: Icons.close),
                ],
              ),
            ),
            Container(height: 1, color: borderColor),
            Expanded(
              child: Row(
                children: [
                  // Vertical Tab Bar
                  Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border(right: BorderSide(width: 1, color: borderColor)),
                    ),
                    child: Column(
                      children: [
                        ..._tabItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tabName = entry.value;
                          final isSelected = index == _selectedTabIndex;

                          return MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) {
                              setState(() {
                                _hoveredTabIndex = index;
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                _hoveredTabIndex = null;
                              });
                            },
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectTab(index);
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? lightBackgroundColor
                                          : (_hoveredTabIndex == index ? lightBackgroundColor : Colors.transparent),
                                  border: Border(
                                    left: BorderSide(
                                      width: 2,
                                      color: isSelected ? highlightBorderColor : Colors.transparent,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  tabName,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : lightTextColor,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  // Content Area
                  Expanded(child: Container(color: backgroundColor, child: _buildTabContent())),
                ],
              ),
            ),
            Container(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [ElevatedButton(onPressed: _onSave, style: commonButtonStyle, child: const Text('Save'))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
