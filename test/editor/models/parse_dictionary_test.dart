import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/grammar_request.dart';

void assertSingleHeader(String input) {
  final parser = BruRequestGrammar().build();
  final result = parser.parse(input);

  expect(result.isSuccess, isTrue);
  expect(result.value['headers'], equals({'hello': 'world'}));
}

void main() {
  test('Parses meta block', () {
    final bru = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}''';
    final parser = BruRequestGrammar().build();
    final result = parser.parse(bru);
    expect(result.isSuccess, isTrue);
    expect(result.value['meta']['name'], equals('Send Bulk SMS'));
  });

  test('Parses multiple auth blocks', () {
    final parser = BruRequestGrammar().build();
    final bru = '''
auth:basic {
  username: john
  password: secret
}

auth:bearer {
  token: 123
}
''';
    final result = parser.parse(bru);
    expect(result.isSuccess, isTrue);
    expect(result.value['auth:basic']['username'], equals('john'));
    expect(result.value['auth:bearer']['token'], equals('123'));
  });

  group('headers parser', () {
    test('should parse empty header', () {
      final input = '''
headers {
}''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      expect(result.value['headers'], equals({}));
    });

    test('should parse single header', () {
      final input = '''
headers {
  hello: world
}''';
      assertSingleHeader(input);
    });

    test('should parse single header with spaces', () {
      final input = '''
headers {
      hello: world
}''';
      assertSingleHeader(input);
    });

    test('should parse single header with spaces and newlines', () {
      final input = '''
headers {

      hello: world
}''';
      assertSingleHeader(input);
    });

    test('should parse single header with empty value', () {
      final input = '''
headers {
  hello:
}''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      expect(result.value['headers'], equals({'hello': ''}));
    });

    test('should parse multi headers', () {
      final input = '''
headers {
  content-type: application/json

  Authorization: JWT secret
}''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      expect(result.value['headers'], equals({'content-type': 'application/json', 'Authorization': 'JWT secret'}));
    });

    test('should parse disabled headers', () {
      final input = '''
headers {
  ~content-type: application/json
}''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      expect(result.value['headers'], equals({'~content-type': 'application/json'}));
    });

    test('should parse empty url', () {
      final input = '''
get {
  url:
  body: json
}''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isTrue);
      expect(result.value['get'], equals({'url': '', 'body': 'json'}));
    });

    test('should fail on invalid header', () {
      final input = '''
headers {
  hello: world
  foo
}''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isFalse);
    });

    test('should fail on invalid header format', () {
      final input = '''
headers {
  hello: world
  foo: bar}''';
      final parser = BruRequestGrammar().build();
      final result = parser.parse(input);

      expect(result.isSuccess, isFalse);
    });
  });
}
