import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../common/style.dart';

class SplashScreen extends StatelessWidget {
  final void Function() onContainersButtonPressed;

  const SplashScreen({super.key, required this.onContainersButtonPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          SvgPicture.asset(
            'fonts/docker-mark-blue.svg',
            allowDrawingOutsideViewBox: true,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(highlightBorderColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 24),
          const SelectableText(
            'Docker Network Monitor',
            style: TextStyle(color: lightTextColor, fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 600,
            child: SelectableText(
              'Monitor network traffic to and from your containers.\n Start by clicking below to run the Trayce Agent container:',
              style: TextStyle(color: lightTextColor, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                key: const Key('editor_tabs_open_collection_button'),
                onPressed: onContainersButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: lightTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: lightTextColor.withOpacity(0.3)),
                  ),
                ),
                child: const Text('Containers'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
