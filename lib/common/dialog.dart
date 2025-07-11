import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';

Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String yesText = 'Yes',
  String noText = 'No',
  required VoidCallback onAccept,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: lightBackgroundColor,
        shape: dialogShape,
        title: Text(title, style: const TextStyle(color: lightTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: lightTextColor, fontSize: 14)),
        actions: [
          TextButton(
            key: const Key('confirm_dialog_no_btn'),
            style: commonButtonStyle,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(noText),
          ),
          TextButton(
            key: const Key('confirm_dialog_yes_btn'),
            style: commonButtonStyle,
            onPressed: () {
              Navigator.of(context).pop(true);
              onAccept();
            },
            child: Text(yesText),
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}
