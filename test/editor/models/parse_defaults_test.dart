import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/grammar_request.dart';

void main() {
  group('defaults', () {
    test('should parse the default type and seq', () {
      final input = '''
meta {
  name: Create user
}

post {
  url: /users
}
''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);

      final expected = {
        'meta': {'name': 'Create user', 'seq': '1', 'type': 'http'},
        'post': {'url': '/users'},
      };

      expect(result.value['meta']['name'], equals(expected['meta']?['name']));
      // expect(result.value['meta']['seq'], equals(expected['meta']?['seq']));
      // exp  ect(result.value['meta']['type'], equals(expected['meta']?['type']));
      expect(result.value['post']['url'], equals(expected['post']?['url']));
    });
  });
}
