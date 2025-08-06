import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:trayce/common/dropdown_style.dart';
import 'package:trayce/common/style.dart';
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/widgets/common/text_input.dart';
import 'package:trayce/editor/widgets/flow_editor_http/auth_api_key_controller.dart';

class AuthApiKeyForm extends StatefulWidget {
  final AuthApiKeyControllerI controller;
  final FocusNode keyFocusNode;
  final FocusNode valueFocusNode;
  final FocusNode placementFocusNode;

  const AuthApiKeyForm({
    super.key,
    required this.controller,
    required this.keyFocusNode,
    required this.valueFocusNode,
    required this.placementFocusNode,
  });

  @override
  State<AuthApiKeyForm> createState() => _AuthApiKeyFormState();
}

class _AuthApiKeyFormState extends State<AuthApiKeyForm> {
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
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Placement:',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Select where to place the API key',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 30,
                      child: TextInput(
                        key: const Key('auth_api_key_form_key_input'),
                        controller: widget.controller.getKeyController(),
                        focusNode: widget.keyFocusNode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 30,
                      child: TextInput(
                        key: const Key('auth_api_key_form_value_input'),
                        controller: widget.controller.getValueController(),
                        focusNode: widget.valueFocusNode,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF474747), width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButton2<String>(
                        key: const Key('flow_editor_auth_api_key_placement_dropdown'),
                        focusNode: widget.placementFocusNode,
                        value: widget.controller.getPlacement().name,
                        underline: Container(),
                        dropdownStyleData: DropdownStyleData(
                          decoration: dropdownDecoration,
                          width: 120,
                          openInterval: Interval(0.0, 0.0),
                        ),
                        buttonStyleData: ButtonStyleData(padding: const EdgeInsets.only(left: 4, top: 2, right: 4)),
                        menuItemStyleData: menuItemStyleData,
                        iconStyleData: iconStyleData,
                        style: textFieldStyle,
                        isExpanded: true,
                        items:
                            ApiKeyPlacement.values.map((ApiKeyPlacement placement) {
                              return DropdownMenuItem<String>(
                                value: placement.name,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(placement.name),
                                ),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            widget.controller.setPlacement(
                              ApiKeyPlacement.values.firstWhere((e) => e.name == newValue),
                            );
                            setState(() {}); // Trigger UI update
                            widget.placementFocusNode.requestFocus();
                          }
                        },
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
