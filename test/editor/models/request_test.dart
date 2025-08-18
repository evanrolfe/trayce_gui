import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:trayce/editor/models/auth.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/multipart_file.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/models/request.dart';
import 'package:trayce/editor/models/variable.dart';

void main() {
  test('creating a GET request with headers and variables', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: 'https://example.com{{A_var}}',
      bodyType: BodyType.none,
      authType: AuthType.none,
      params: [],
      headers: [Header(name: '{{C_var}}', value: '{{B_var}}', enabled: true)],
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'get');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect(httpRequest.headers['x-trayce-token'], 'abcd1234');
  });

  test('creating a POST request with text body', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: 'https://example.com/test_endpoint',
      bodyType: BodyType.text,
      bodyText: TextBody(content: 'helloworld, my token is {{B_var}}'),
      authType: AuthType.none,
      params: [],
      headers: [],
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'post');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect((httpRequest as http.Request).body, 'helloworld, my token is abcd1234');
  });

  test('creating a POST request with json body', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: 'https://example.com/test_endpoint',
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello": "world"}'),
      authType: AuthType.none,
      params: [],
      headers: [Header(name: 'x-trayce-token', value: 'abcd1234', enabled: true)],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'post');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect((httpRequest as http.Request).body, '{"hello": "world"}');
    expect(httpRequest.headers['x-trayce-token'], 'abcd1234');
  });

  test('creating a POST request with xml body', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: 'https://example.com/test_endpoint',
      bodyType: BodyType.xml,
      authType: AuthType.none,
      bodyXml: XmlBody(content: '<hello>world</hello>'),
      params: [],
      headers: [Header(name: 'x-trayce-token', value: 'abcd1234', enabled: false)],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'post');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect((httpRequest as http.Request).body, '<hello>world</hello>');
    expect(httpRequest.headers['x-trayce-token'], null);
  });

  test('creating a POST request with form-urlencoded body', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: 'https://example.com/test_endpoint',
      authType: AuthType.none,
      bodyType: BodyType.formUrlEncoded,
      bodyFormUrlEncoded: FormUrlEncodedBody(
        params: [
          Param(name: 'hello', value: '{{A_var}}', type: ParamType.form, enabled: true),
          Param(name: 'howare', value: '{{B_var}}', type: ParamType.form, enabled: true),
        ],
      ),
      params: [],
      headers: [Header(name: 'X-Trayce-Token', value: 'abcd1234', enabled: true)],
      requestVars: [
        Variable(name: 'A_var', value: 'world', enabled: true),
        Variable(name: 'B_var', value: 'you?', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'post');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect((httpRequest as http.Request).body, 'hello=world&howare=you%3F');
    expect(httpRequest.headers['X-Trayce-Token'], 'abcd1234');
  });

  test('creating a POST request with multipart-form body', () async {
    final currentDir = Directory.current.path;
    final testFilePath = '$currentDir/VERSION';

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: 'https://example.com/test_endpoint',
      authType: AuthType.none,
      bodyType: BodyType.multipartForm,
      bodyMultipartForm: MultipartFormBody(
        files: [
          MultipartFile(name: '{{A_var}}', value: testFilePath, contentType: 'image/jpg', enabled: true),
          MultipartFile(name: 'howare', value: testFilePath, contentType: '{{B_var}}', enabled: true),
        ],
      ),
      params: [],
      headers: [Header(name: 'x-trayce-token', value: 'abcd1234', enabled: false)],
      requestVars: [
        Variable(name: 'A_var', value: 'hello', enabled: true),
        Variable(name: 'B_var', value: 'text/plain', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'post');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect(httpRequest, isA<http.MultipartRequest>());

    final multipartRequest = httpRequest as http.MultipartRequest;
    expect(multipartRequest.files.length, 2);
    expect(multipartRequest.files[0].field, 'hello');
    expect(multipartRequest.files[0].filename, 'VERSION');
    expect(multipartRequest.files[1].field, 'howare');
    expect(multipartRequest.files[1].filename, 'VERSION');
  });

  test('creating a POST request with binary file body', () async {
    final currentDir = Directory.current.path;

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: 'https://example.com/test_endpoint',
      authType: AuthType.none,
      bodyType: BodyType.file,
      bodyFile: FileBody(
        files: [
          FileBodyItem(filePath: '$currentDir/VERSION', contentType: '{{B_var}}', selected: true),
          FileBodyItem(filePath: '$currentDir/schema.sql', contentType: 'text/plain', selected: false),
        ],
      ),
      params: [],
      headers: [Header(name: 'x-trayce-token', value: 'abcd1234', enabled: false)],
      requestVars: [
        Variable(name: 'A_var', value: 'hello', enabled: true),
        Variable(name: 'B_var', value: 'text/plain', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'post');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect(httpRequest.headers['content-type'], 'text/plain');

    // Verify the file content was read
    final file = File('$currentDir/VERSION');
    final expectedContent = await file.readAsBytes();
    expect((httpRequest as http.Request).bodyBytes, expectedContent);
  });

  test('creating a GET request with basic auth', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: 'https://example.com{{A_var}}',
      bodyType: BodyType.none,
      authType: AuthType.basic,
      authBasic: BasicAuth(username: '{{B_var}}', password: '{{C_var}}'),
      params: [],
      headers: [],
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'get');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect(httpRequest.headers['Authorization'], 'Basic YWJjZDEyMzQ6eC10cmF5Y2UtdG9rZW4=');
  });

  test('creating a GET request with bearer auth', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: 'https://example.com{{A_var}}',
      bodyType: BodyType.none,
      authType: AuthType.bearer,
      authBearer: BearerAuth(token: '{{B_var}}'),
      params: [],
      headers: [],
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'get');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect(httpRequest.headers['Authorization'], 'Bearer abcd1234');
  });

  test('creating a GET request with apikey in header auth', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: 'https://example.com{{A_var}}',
      bodyType: BodyType.none,
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.header),
      params: [],
      headers: [],
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'get');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint');
    expect(httpRequest.headers['x-trayce-token'], 'abcd1234');
  });

  test('creating a GET request with apikey in query params auth', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: 'https://example.com{{A_var}}?hello=world',
      bodyType: BodyType.none,
      authType: AuthType.apikey,
      authApiKey: ApiKeyAuth(key: '{{C_var}}', value: '{{B_var}}', placement: ApiKeyPlacement.queryparams),
      params: [],
      headers: [],
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: true),
        Variable(name: 'B_var', value: 'abcd1234', enabled: true),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: true),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'get');
    expect(httpRequest.url.toString(), 'https://example.com/test_endpoint?hello=world&x-trayce-token=abcd1234');
  });

  test('creating a request with disabled variables should not interpolate', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: 'https://example.com{{A_var}}',
      bodyType: BodyType.none,
      authType: AuthType.none,
      params: [],
      headers: [Header(name: '{{C_var}}', value: '{{B_var}}', enabled: true)],
      requestVars: [
        Variable(name: 'A_var', value: '/test_endpoint', enabled: false),
        Variable(name: 'B_var', value: 'abcd1234', enabled: false),
        Variable(name: 'C_var', value: 'x-trayce-token', enabled: false),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'get');
    expect(httpRequest.url.toString(), 'https://example.com%7B%7Ba_var%7D%7D');
    expect(httpRequest.headers['{{C_var}}'], '{{B_var}}');
  });

  test('creating a request with mixed enabled/disabled variables', () async {
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: 'https://example.com/{{A_var}}/{{B_Var}}',
      bodyType: BodyType.none,
      authType: AuthType.none,
      params: [],
      headers: [],
      requestVars: [
        Variable(name: 'A_var', value: 'enabled', enabled: true),
        Variable(name: 'B_var', value: 'disabled', enabled: false),
      ],
      responseVars: [],
      assertions: [],
    );

    final httpRequest = await request.toHttpRequest();

    expect(httpRequest.method, 'get');
    expect(httpRequest.url.toString(), 'https://example.com/enabled/%7B%7BB_Var%7D%7D');
  });
}
