import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:trayce/common/style.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthNotImplemented extends StatelessWidget {
  final String authType;

  const AuthNotImplemented({super.key, required this.authType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SelectableText.rich(
        TextSpan(
          text: 'Sorry! $authType is not yet implemented.\n\nPlease check our releases page on ',
          style: TextStyle(color: lightTextColor, fontSize: 16),
          children: [
            TextSpan(
              text: 'Github',
              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 16),
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () async {
                      final url = Uri.parse('https://github.com/evanrolfe/trayce_gui/releases');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
            ),
            TextSpan(text: '.', style: TextStyle(color: lightTextColor, fontSize: 16)),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
