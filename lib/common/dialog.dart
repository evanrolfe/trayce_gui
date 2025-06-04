import 'package:flutter/material.dart';

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
        backgroundColor: const Color(0xFF252526),
        title: Text(title),
        content: Text(message, style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(noText)),
          TextButton(
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
