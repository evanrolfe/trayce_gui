import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/grammar_request.dart';

void main() {
  group('assert parser', () {
    test('should parse assert statement', () {
      final input = '''
assert {
  res("data.airports").filter(a => a.code ==="BLR").name: "Bangalore International Airport"
}
''';

      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);

      // The parser returns a map like: {'assert': {key: value}}
      final assertBlock = result.value['assert'] as Map<String, dynamic>;
      expect(assertBlock, isNotNull);

      // Convert to the expected structure
      final assertions =
          assertBlock.entries.map((entry) {
            return {'name': entry.key, 'value': entry.value, 'enabled': true};
          }).toList();

      final expected = {
        'assertions': [
          {
            'name': 'res("data.airports").filter(a => a.code ==="BLR").name',
            'value': '"Bangalore International Airport"',
            'enabled': true,
          },
        ],
      };

      expect({'assertions': assertions}, equals(expected));
    });
  });
}
