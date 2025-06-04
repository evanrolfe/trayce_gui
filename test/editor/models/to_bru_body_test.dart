import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/editor/models/parse/parse_request.dart';

void main() {
  test('body to bru - json', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

post {
  url: https://api.textlocal.in/send/:id
  body: json
}

body:json {
  {
    "hello": "world"
  }
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('body to bru - text', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

post {
  url: https://api.textlocal.in/send/:id
  body: text
}

body:text {
  This is a text body
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('body to bru - xml', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

post {
  url: https://api.xmllocal.in/send/:id
  body: xml
}

body:xml {
  <xml>
    <name>John</name>
    <age>30</age>
  </xml>
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('body to bru - graphql', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

post {
  url: https://api.xmllocal.in/send/:id
  body: graphql
}

body:graphql {
  {
    launchesPast {
      launch_site {
        site_name
      }
      launch_success
    }
  }
}

body:graphql:vars {
  {
    "limit": 5
  }
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('body to bru - form-urlencoded', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

post {
  url: https://api.xmllocal.in/send/:id
  body: form-urlencoded
}

body:form-urlencoded {
  apikey: secret
  numbers: +91998877665
  ~message: hello
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('body to bru - multipart-form', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

post {
  url: https://api.xmllocal.in/send/:id
  body: multipart-form
}

body:multipart-form {
  apikey: secret
  numbers: +91998877665
  ~message: hello
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });

  test('body to bru - file', () async {
    // Load the BRU file
    final input = '''meta {
  name: Send Bulk SMS
  type: http
  seq: 1
}

post {
  url: https://api.xmllocal.in/send/:id
  body: file
}

body:file {
  file: @file(path/to/file1.json) @contentType(application/json)
  ~file: @file(path/to/file2.json) @contentType(application/json)
  ~file: @file(path/to/file3.json) @contentType(application/json)
}
''';

    // Parse the BRU data
    final result = parseRequest(input);
    // print("--->${result.toBru()}<----");
    expect(result.toBru(), input);
  });
}
