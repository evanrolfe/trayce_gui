import 'package:flutter/material.dart';
import 'package:trayce/editor/models/header.dart';

class HeadersTableReadOnly extends StatelessWidget {
  final List<Header> headers;

  const HeadersTableReadOnly({super.key, this.headers = const []});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: const Color(0xFF474747), width: 1),
      children: [
        const TableRow(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Name', style: TextStyle(color: Color(0xFFD4D4D4), fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Value', style: TextStyle(color: Color(0xFFD4D4D4), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        ...headers
            .map(
              (header) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(header.name, style: const TextStyle(color: Color(0xFFD4D4D4))),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SelectableText(header.value, style: const TextStyle(color: Color(0xFFD4D4D4))),
                  ),
                ],
              ),
            )
            .toList(),
      ],
    );
  }
}
