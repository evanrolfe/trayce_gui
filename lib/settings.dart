import 'dart:async';
import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trayce/agent/server.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/common/widgets/hoverable_icon_button.dart';
import 'package:trayce/editor/repo/config_repo.dart';
import 'package:trayce/network/models/license_key.dart';
import 'package:trayce/network/repo/containers_repo.dart';
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
  late final TextEditingController _licenseController;
  late final TextEditingController _nodejsCommandController;

  bool _isVerifying = false;
  bool? _isVerified;
  late final StreamSubscription _verificationSubscription;
  // Tab management
  int _selectedTabIndex = 0;
  int? _hoveredTabIndex;

  // Tab items
  final List<String> _tabItems = ['License', 'Editor', 'Network'];

  @override
  void initState() {
    super.initState();

    _licenseController = TextEditingController();
    _nodejsCommandController = TextEditingController();

    // Subscribe to verification events
    _verificationSubscription = context.read<EventBus>().on<EventAgentVerified>().listen((event) {
      setState(() {
        _isVerifying = false;
        _isVerified = event.valid;
      });
    });

    _loadLicenseKey();
  }

  Future<void> _loadLicenseKey() async {
    final licenseKey = await context.read<ContainersRepo>().getLicenseKey();
    if (licenseKey != null) {
      _licenseController.text = licenseKey.key;
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _verificationSubscription.cancel();
    super.dispose();
  }

  void _verifyLicense() async {
    final key = _licenseController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isVerifying = true);

    final isValid = await _isLicenseValid(key);

    setState(() {
      _isVerifying = false;
      _isVerified = isValid;
    });

    if (!mounted) return;
    context.read<ContainersRepo>().setLicenseKey(LicenseKey(key, isValid));
  }

  Future<bool> _isLicenseValid(String licenseKey) async {
    final trayceApiUrl = context.read<ConfigRepo>().get().trayceApiUrl;
    final encodedLicenseKey = Uri.encodeComponent(licenseKey);
    final url = '$trayceApiUrl/verify/$encodedLicenseKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'active';
      }
      return false;
    } catch (e) {
      print("ERROR: $e");
      return false;
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onSave() {
    Navigator.of(context).pop();
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0: // License
        return _buildLicenseContent();
      case 1: // Editor
        return _buildEditorContent();
      case 2: // Network
        return _buildNetworkContent();
      default:
        return _buildLicenseContent();
    }
  }

  Widget _buildLicenseContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 16),
          child: Text(
            'License',
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
                  text:
                      'Trayce may be evaluated for free, however a license must be purchased for continued use. You can purchase one from the link below:\n',
                  style: TextStyle(color: lightTextColor, fontSize: 14),
                  children: [
                    TextSpan(
                      text: 'https://get.trayce.dev/',
                      style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 14),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () async {
                              final url = Uri.parse('https://get.trayce.dev/');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SelectableText(
                'License Key',
                style: TextStyle(color: lightTextColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('license-key-input'),
                      controller: _licenseController,
                      style: textFieldStyle,
                      decoration: textFieldDecor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _verifyLicense,
                    style: commonButtonStyle,
                    child:
                        _isVerifying
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                            : const Text('Verify'),
                  ),
                ],
              ),
              if (_isVerified != null) ...[
                const SizedBox(height: 8),
                Text(
                  _isVerified! ? 'License key is valid' : 'License key is invalid',
                  style: TextStyle(color: _isVerified! ? Colors.green : Colors.red, fontSize: 12),
                ),
              ],
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
                              'NodeJS Command:',
                              style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Tooltip(
                              message: 'Enter the command to run NodeJS (only necessary if you want to run scripts)',
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
                        controller: _nodejsCommandController,
                        style: textFieldStyle,
                        decoration: textFieldDecor.copyWith(hintText: 'node'),
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
          padding: const EdgeInsets.all(16),
          child: Text(
            'Network settings will be available here.',
            style: TextStyle(color: lightTextColor, fontSize: 14),
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
