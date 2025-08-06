import 'package:flutter/material.dart';
import 'package:trayce/editor/widgets/common/text_input.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_api_key_controller.dart';

class AuthApiKeyForm extends StatelessWidget {
  final AuthApiKeyControllerI controller;
  final FocusNode keyFocusNode;
  final FocusNode valueFocusNode;

  const AuthApiKeyForm({super.key, required this.controller, required this.keyFocusNode, required this.valueFocusNode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Key:',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Enter the key for the API key',
                          child: const Icon(Icons.help_outline, color: Color(0xFF666666), size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Value:',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Enter the value of the API key',
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
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: TextInput(
                        key: const Key('auth_api_key_form_key_input'),
                        controller: controller.getKeyController(),
                        focusNode: keyFocusNode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 30,
                      child: TextInput(
                        key: const Key('auth_api_key_form_value_input'),
                        controller: controller.getValueController(),
                        focusNode: valueFocusNode,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
