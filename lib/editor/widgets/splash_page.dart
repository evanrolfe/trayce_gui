import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:trayce/common/events.dart';

import '../../common/style.dart';

class SplashPage extends StatelessWidget {
  final FocusNode focusNode;

  const SplashPage({super.key, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 100),
          SvgPicture.asset(
            'fonts/logo.svg',
            allowDrawingOutsideViewBox: true,
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(highlightBorderColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 24),
          const SelectableText('Trayce Request Editor', style: TextStyle(color: lightTextColor, fontSize: 24)),
          const SizedBox(height: 24),
          const SelectableText(
            'Start by creating or opening a collection:',
            style: TextStyle(color: lightTextColor, fontSize: 18),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                key: const Key('editor_tabs_new_collection_button'),
                onPressed: () {
                  context.read<EventBus>().fire(EventNewCollectionIntent());
                  FocusScope.of(context).requestFocus(focusNode);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: lightTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: lightTextColor.withOpacity(0.3)),
                  ),
                ),
                child: const Text('New Collection'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                key: const Key('editor_tabs_open_collection_button'),
                onPressed: () {
                  context.read<EventBus>().fire(EventOpenCollectionIntent());
                  FocusScope.of(context).requestFocus(focusNode);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: lightTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(color: lightTextColor.withOpacity(0.3)),
                  ),
                ),
                child: const Text('Open Collection'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
