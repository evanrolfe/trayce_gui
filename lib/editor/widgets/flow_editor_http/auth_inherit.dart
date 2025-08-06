import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';

class AuthInherit extends StatelessWidget {
  const AuthInherit({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText.rich(
            TextSpan(
              style: const TextStyle(color: lightTextColor, fontSize: 14),
              children: const [TextSpan(text: 'Auth inherited from the nearest folder or collection.')],
            ),
          ),
        ],
      ),
    );
  }
}
