import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/parse_environment.dart';
import 'package:trayce/editor/models/variable.dart';

void main() {
  group('env parser', () {
    test('should parse empty vars', () {
      final input = '''vars {
}''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, isEmpty);
    });

    test('should parse single var line', () {
      final input = '''vars {
  url: http://localhost:3000
}''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
      ]);
    });

    test('should parse multiple var lines', () {
      final input = '''vars {
  url: http://localhost:3000
  port: 3000
  ~token: secret
}''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'port')
            .having((v) => v.value, 'value', '3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'token')
            .having((v) => v.value, 'value', 'secret')
            .having((v) => v.enabled, 'enabled', false)
            .having((v) => v.secret, 'secret', false),
      ]);
    });

    test('should gracefully handle empty lines and spaces', () {
      final input = '''vars {
      url:     http://localhost:3000
  port: 3000
}

''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'port')
            .having((v) => v.value, 'value', '3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
      ]);
    });

    test('should parse vars with empty values', () {
      final input = '''
vars {
  url:
  phone:
  api-key:
}
''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', '')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'phone')
            .having((v) => v.value, 'value', '')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'api-key')
            .having((v) => v.value, 'value', '')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
      ]);
    });

    test('should parse empty secret vars', () {
      final input = '''
vars {
  url: http://localhost:3000
}

vars:secret [

]
''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
      ]);
    });

    test('should parse secret vars', () {
      final input = '''vars {
  url: http://localhost:3000
}

vars:secret [
  token
]''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'token')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', true),
      ]);
    });

    test('should parse multiline secret vars', () {
      final input = '''vars {
  url: http://localhost:3000
}

vars:secret [
  access_token,
  access_secret,

  ~access_password
]
''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'access_token')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', true),
        isA<Variable>()
            .having((v) => v.name, 'name', 'access_secret')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', true),
        isA<Variable>()
            .having((v) => v.name, 'name', 'access_password')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', false)
            .having((v) => v.secret, 'secret', true),
      ]);
    });

    test('should parse inline secret vars', () {
      final input = '''
vars {
  url: http://localhost:3000
}

vars:secret [access_key]
''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'access_key')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', true),
      ]);
    });

    test('should parse inline multiple secret vars', () {
      final input = '''
vars {
  url: http://localhost:3000
}

vars:secret [access_key,access_secret,    access_password  ]
''';

      final env = parseEnvironment(input, File('test/editor/models/fixtures/environment.bru'));
      expect(env.vars, [
        isA<Variable>()
            .having((v) => v.name, 'name', 'url')
            .having((v) => v.value, 'value', 'http://localhost:3000')
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', false),
        isA<Variable>()
            .having((v) => v.name, 'name', 'access_key')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', true),
        isA<Variable>()
            .having((v) => v.name, 'name', 'access_secret')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', true),
        isA<Variable>()
            .having((v) => v.name, 'name', 'access_password')
            .having((v) => v.value, 'value', isNull)
            .having((v) => v.enabled, 'enabled', true)
            .having((v) => v.secret, 'secret', true),
      ]);
    });
  });
}
