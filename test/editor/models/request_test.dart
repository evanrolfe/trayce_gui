import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_test_handler/shelf_test_handler.dart';
import 'package:trayce/editor/models/body.dart';
import 'package:trayce/editor/models/header.dart';
import 'package:trayce/editor/models/param.dart';
import 'package:trayce/editor/models/request.dart';

const jsonResponse = '{"message":"Hello, World!","status":200}';

class HttpTestServer {
  late ShelfTestServer server;
  shelf.Request? sentRequest;
  String? sentRequestBody;

  HttpTestServer(this.server);

  static Future<HttpTestServer> create() async {
    final server = await ShelfTestServer.create();
    return HttpTestServer(server);
  }

  Uri url() => server.url;

  Future<void> close() async {
    await server.close(force: true);
  }

  newHandler(String method, String path) {
    sentRequest = null;
    sentRequestBody = null;

    server.handler.expect(method, path, (request) async {
      sentRequest = request;
      sentRequestBody = await request.readAsString();
      return shelf.Response.ok(jsonResponse, headers: {"content-type": "application/json"});
    });
  }
}

late HttpTestServer mockServer;

void main() {
  setUpAll(() async {
    mockServer = await HttpTestServer.create();
  });

  tearDownAll(() async {
    await mockServer.close();
  });

  test('sending a GET request', () async {
    mockServer.newHandler('GET', '/test_endpoint');

    final url = '${mockServer.url().toString()}/test_endpoint';
    print('====> Sending request to $url');

    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'get',
      url: url,
      bodyType: BodyType.none,
      params: [],
      headers: [],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );

    final response = await request.send();

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);
  });

  test('sending a POST request with text body', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}/test_endpoint';
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.text,
      bodyText: TextBody(content: 'helloworld'),
      params: [],
      headers: [],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );

    final response = await request.send();

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);

    expect(mockServer.sentRequestBody, 'helloworld');
  });

  test('sending a POST request with json body', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}/test_endpoint';
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.json,
      bodyJson: JsonBody(content: '{"hello": "world"}'),
      params: [],
      headers: [Header(name: 'x-trayce-token', value: 'abcd1234', enabled: true)],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );

    final response = await request.send();

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);

    expect(mockServer.sentRequestBody, '{"hello": "world"}');
    // expect(mockServer.sentRequest!.headers['content-type'], 'application/json');
    expect(mockServer.sentRequest!.headers['x-trayce-token'], 'abcd1234');
  });

  test('sending a POST request with xml body', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}/test_endpoint';
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.xml,
      bodyXml: XmlBody(content: '<hello>world</hello>'),
      params: [],
      headers: [Header(name: 'x-trayce-token', value: 'abcd1234', enabled: false)],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );

    final response = await request.send();

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);

    expect(mockServer.sentRequestBody, '<hello>world</hello>');
    // expect(mockServer.sentRequest!.headers['content-type'], 'application/json');
    expect(mockServer.sentRequest!.headers['x-trayce-token'], null);
  });

  test('sending a POST request with form-urlencoded body', () async {
    mockServer.newHandler('POST', '/test_endpoint');

    final url = '${mockServer.url().toString()}/test_endpoint';
    final request = Request(
      name: 'Test Request',
      type: 'http',
      seq: 1,
      method: 'post',
      url: url,
      bodyType: BodyType.formUrlEncoded,
      bodyFormUrlEncoded: FormUrlEncodedBody(
        params: [
          Param(name: 'hello', value: 'world', type: ParamType.form, enabled: true),
          Param(name: 'howare', value: 'you?', type: ParamType.form, enabled: true),
        ],
      ),
      params: [],
      headers: [Header(name: 'x-trayce-token', value: 'abcd1234', enabled: false)],
      requestVars: [],
      responseVars: [],
      assertions: [],
    );

    final response = await request.send();

    expect(response.statusCode, 200);
    expect(response.body, jsonResponse);

    expect(mockServer.sentRequestBody, 'hello=world&howare=you%3F');
  });
}
