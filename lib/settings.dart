import 'dart:async';
import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trayce/agent/server.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/network/repo/containers_repo.dart';

Future<void> showSettingsModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (dialogContext) => const SettingsModal(),
  );
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

    final repo = context.read<ContainersRepo>();

    _licenseController = TextEditingController(text: repo.licenseKey);

    // Subscribe to verification events
    _verificationSubscription = context.read<EventBus>().on<EventAgentVerified>().listen((event) {
      setState(() {
        _isVerifying = false;
        _isVerified = event.valid;
      });
    });
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _verificationSubscription.cancel();
    super.dispose();
  }

  Future<bool> _verifyLicense(String licenseKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://get.trayce.dev/verify/$licenseKey'),
      );

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
      backgroundColor: const Color(0xFF252526),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        width: 400,
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
                  style: TextStyle(
                    color: Color(0xFFD4D4D4),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFD4D4D4),
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'License Key',
              style: TextStyle(
                color: Color(0xFFD4D4D4),
                fontSize: 14,
              ),
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
                  onPressed: _isVerifying
                      ? null
                      : () async {
                          final licenseKey = _licenseController.text.trim();
                          if (licenseKey.isNotEmpty) {
                            setState(() => _isVerifying = true);

                            final isValid = await _verifyLicense(licenseKey);

                            setState(() {
                              _isVerifying = false;
                              _isVerified = isValid;
                            });

                            context.read<ContainersRepo>().setLicenseKey(licenseKey);
                          }
                        },
                  style: commonButtonStyle,
                  child: _isVerifying
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
                style: TextStyle(
                  color: _isVerified! ? Colors.green : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final licenseKey = _licenseController.text.trim();
                    if (licenseKey.isNotEmpty) {
                      final isValid = await _verifyLicense(licenseKey);

                      setState(() {
                        _isVerified = isValid;
                      });

                      context.read<ContainersRepo>().setLicenseKey(licenseKey);
                      Navigator.of(context).pop();
                    }
                  },
                  style: commonButtonStyle,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
