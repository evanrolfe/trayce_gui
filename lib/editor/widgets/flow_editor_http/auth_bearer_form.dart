import 'package:flutter/material.dart';
import 'package:trayce/editor/widgets/common/text_input.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_bearer_controller.dart';

class AuthBearerForm extends StatelessWidget {
  final AuthBearerController controller;
  final FocusNode tokenFocusNode;

  const AuthBearerForm({super.key, required this.controller, required this.tokenFocusNode});

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
                          'Bearer Token:',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Enter your bearer token, without the "Bearer " prefix',
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
                        key: const Key('auth_bearer_form_token_input'),
                        controller: controller.tokenController,
                        focusNode: tokenFocusNode,
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
