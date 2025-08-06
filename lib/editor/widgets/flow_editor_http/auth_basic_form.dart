import 'package:flutter/material.dart';
import 'package:trayce/editor/widgets/common/text_input.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_basic_controller.dart';

class AuthBasicForm extends StatelessWidget {
  final AuthBasicControllerI controller;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;

  const AuthBasicForm({
    super.key,
    required this.controller,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
  });

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
                          'Username:',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Enter your username for basic authentication',
                          child: const Icon(Icons.help_outline, color: Color(0xFF666666), size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Password:',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Enter your password for basic authentication',
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
                        key: const Key('auth_basic_form_username_input'),
                        controller: controller.getUsernameController(),
                        focusNode: usernameFocusNode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 30,
                      child: TextInput(
                        key: const Key('auth_basic_form_password_input'),
                        controller: controller.getPasswordController(),
                        focusNode: passwordFocusNode,
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
