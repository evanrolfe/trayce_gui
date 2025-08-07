import 'dart:async';
import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trayce/agent/server.dart';
import 'package:trayce/common/config.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/common/widgets/hoverable_icon_button.dart';
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
  bool _isVerifying = false;
  bool? _isVerified;
  late final StreamSubscription _verificationSubscription;

  @override
  void initState() {
    super.initState();

    _licenseController = TextEditingController();
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
    final trayceApiUrl = context.read<Config>().trayceApiUrl;
    final url = '$trayceApiUrl/verify/$licenseKey';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: lightBackgroundColor,
      shape: dialogShape,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                HoverableIconButton(onPressed: () => Navigator.of(context).pop(), icon: Icons.close),
              ],
            ),
            const SizedBox(height: 24),
            SelectableText.rich(
              TextSpan(
                text:
                    'Trayce may be evaluated for free, however a license must be purchased for continued use. You can purchase one from the link below:\n',
                style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 14),
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
              style: TextStyle(color: Color(0xFFD4D4D4), fontSize: 14, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                  style: commonButtonStyle,
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
