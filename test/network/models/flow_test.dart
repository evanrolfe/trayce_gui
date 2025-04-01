import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:trayce/network/models/flow.dart';
import 'package:trayce/network/models/http_request.dart';
import 'package:trayce/network/models/http_response.dart';

import '../../support/flow_factory.dart';

void main() {
  group('Flow', () {
    final testTime = DateTime.parse('2024-01-01T12:00:00Z');

    group('toMap()', () {
      test('it converts to map correctly', () {
        final flow = buildHttpReqFlow(id: 1, uuid: 'test-uuid');

        final map = flow.toMap();

        expect(map['id'], 1);
        expect(map['uuid'], 'test-uuid');
        expect(map['source'], '192.168.0.1');
        expect(map['dest'], '192.168.0.2');
        expect(map['l4_protocol'], 'tcp');
        expect(map['protocol'], 'http');
        expect(map['operation'], 'GET /');
        expect(map['status'], null);
        expect((map['request_raw'] as Uint8List).length, 96);
        expect((map['response_raw'] as Uint8List).length, 0);
        expect(map['created_at'], testTime.toIso8601String());
      });
    });

    group('fromMap()', () {
      test('it creates from map correctly', () {
        final request =
            HttpRequest(method: 'GET', host: '172.17.0.3', path: '/', httpVersion: 'HTTP/1.1', headers: {}, body: '');
        final response =
            HttpResponse(httpVersion: 'HTTP/1.1', status: 200, statusMsg: 'OK', headers: {}, body: 'Hello World!');
        final map = {
          'id': 1,
          'uuid': 'test-uuid',
          'source': '192.168.0.1',
          'dest': '192.168.0.2',
          'l4_protocol': 'tcp',
          'protocol': 'http',
          'operation': request.operationCol(),
          'status': '200 OK',
          'request_raw': request.toJson(),
          'response_raw': response.toJson(),
          'created_at': testTime.toIso8601String(),
        };

        final flow = Flow.fromMap(map);
        final flowReq = flow.request as HttpRequest;
        final flowResp = flow.response as HttpResponse;
        expect(flow.id, 1);
        expect(flow.uuid, 'test-uuid');
        expect(flow.source, '192.168.0.1');
        expect(flow.dest, '192.168.0.2');
        expect(flow.l4Protocol, 'tcp');
        expect(flow.l7Protocol, 'http');
        expect(flow.operation, 'GET /');
        expect(flow.status, '200 OK');
        expect(flow.requestRaw.length, 96);
        expect(flow.responseRaw.length, 93);

        expect(flowReq.path, '/');
        expect(flowReq.method, 'GET');
        expect(flowReq.host, '172.17.0.3');
        expect(flowReq.httpVersion, 'HTTP/1.1');
        expect(flowReq.headers, {});
        expect(flowReq.body, '');

        expect(flowResp.httpVersion, 'HTTP/1.1');
        expect(flowResp.status, 200);
        expect(flowResp.statusMsg, 'OK');
        expect(flowResp.headers, {});
        expect(flowResp.body, 'Hello World!');

        expect(flow.createdAt, testTime);
      });
    });

    group('copyWith()', () {
      test('it copies only specified fields', () {
        final original = buildHttpReqFlow(id: 1, uuid: 'test-uuid');

        final newTime = DateTime.parse('2024-01-02T12:00:00Z');
        final newBytes = Uint8List.fromList([5, 6, 7, 8]);

        final copied = original.copyWith(
          sourceAddr: '192.168.1.2',
          responseRaw: newBytes,
          status: '200 OK',
          createdAt: newTime,
        );

        // Changed fields
        expect(copied.source, '192.168.1.2');
        expect(copied.responseRaw, newBytes);
        expect(copied.status, '200 OK');
        expect(copied.createdAt, newTime);

        // Unchanged fields
        expect(copied.id, original.id);
        expect(copied.uuid, original.uuid);
        expect(copied.dest, original.dest);
        expect(copied.l4Protocol, original.l4Protocol);
        expect(copied.l7Protocol, original.l7Protocol);
        expect(copied.operation, original.operation);
        expect(copied.requestRaw, original.requestRaw);
      });
    });
  });
}
