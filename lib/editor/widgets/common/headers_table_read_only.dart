import 'package:flutter/material.dart';

class HeadersTableReadOnly extends StatelessWidget {
  const HeadersTableReadOnly({super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF474747), width: 1),
      children: const [
        TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: SelectableText('Cell 1', style: TextStyle(color: Color(0xFFD4D4D4))),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: SelectableText('Cell 2', style: TextStyle(color: Color(0xFFD4D4D4))),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: SelectableText('Cell 3', style: TextStyle(color: Color(0xFFD4D4D4))),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: SelectableText('Cell 4', style: TextStyle(color: Color(0xFFD4D4D4))),
            ),
          ],
        ),
      ],
    );
  }
}
