import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/parse_request.dart';

void main() {
  test('auth to bru - apikey', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

get {
  url: https://api.textlocal.in/send/:id
  auth: apikey
}

auth:apikey {
  key: hello
  value: world
  placement: header
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('auth to bru - awsv4', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

get {
  url: https://api.textlocal.in/send/:id
  auth: awsv4
}

auth:awsv4 {
  accessKeyId: A12345678
  secretAccessKey: thisisasecret
  sessionToken: thisisafakesessiontoken
  service: execute-api
  region: us-east-1
  profileName: test_profile
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('auth to bru - basic', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

get {
  url: https://api.textlocal.in/send/:id
  auth: basic
}

auth:basic {
  username: john
  password: secret
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('auth to bru - bearer', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

get {
  url: https://api.textlocal.in/send/:id
  auth: bearer
}

auth:bearer {
  token: 123
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('auth to bru - digest', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

get {
  url: https://api.textlocal.in/send/:id
  auth: digest
}

auth:digest {
  username: john
  password: secret
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('auth to bru - oauth2', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

get {
  url: https://api.textlocal.in/send/:id
  auth: oauth2
}

auth:oauth2 {
  grant_type: authorization_code
  callback_url: http://localhost:8080/api/auth/oauth2/authorization_code/callback
  authorization_url: http://localhost:8080/api/auth/oauth2/authorization_code/authorize
  access_token_url: http://localhost:8080/api/auth/oauth2/authorization_code/token
  refresh_token_url: http://localhost:8080/api/auth/oauth2/refresh_token
  client_id: client_id_1
  client_secret: client_secret_1
  scope: read write
  state: 807061d5f0be
  pkce: false
  credentials_placement: body
  credentials_id: credentials
  token_placement: header
  token_header_prefix: Bearer
  auto_fetch_token: true
  auto_refresh_token: true
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('auth to bru - wsse', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

get {
  url: https://api.textlocal.in/send/:id
  auth: wsse
}

auth:wsse {
  username: john
  password: secret
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });
}
