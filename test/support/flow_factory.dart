import 'dart:typed_data';

import 'package:trayce/network/models/flow.dart';
import 'package:trayce/network/models/http_request.dart';
import 'package:trayce/network/models/http_response.dart';

Flow buildHttpReqFlow({
  int? id,
  String? uuid,
  String? sourceAddr,
  String? destAddr,
  String? l4Protocol,
  String? l7Protocol,
  HttpRequest? request,
  DateTime? createdAt,
}) {
  request ??= HttpRequest(method: 'GET', host: '172.17.0.3', path: '/', httpVersion: 'HTTP/1.1', headers: {}, body: '');

  return Flow(
    id: id,
    uuid: uuid,
    source: sourceAddr ?? '192.168.0.1',
    dest: destAddr ?? '192.168.0.2',
    l4Protocol: l4Protocol ?? 'tcp',
    l7Protocol: l7Protocol ?? 'http',
    operation: request.operationCol(),
    request: request,
    requestRaw: request.toJson(),
    responseRaw: Uint8List(0),
    createdAt: createdAt ?? DateTime.parse('2024-01-01T12:00:00Z'),
  );
}

Flow buildHttpRespFlow({
  int? id,
  String? uuid,
  String? sourceAddr,
  String? destAddr,
  String? l4Protocol,
  String? l7Protocol,
  HttpResponse? response,
  DateTime? createdAt,
}) {
  response ??= HttpResponse(httpVersion: 'HTTP/1.1', status: 200, statusMsg: 'OK', headers: {}, body: 'Hello World!');

  return Flow(
    id: id,
    uuid: uuid,
    source: sourceAddr ?? '192.168.0.1',
    dest: destAddr ?? '192.168.0.2',
    l4Protocol: l4Protocol ?? 'tcp',
    l7Protocol: l7Protocol ?? 'http',
    operation: '',
    response: response,
    requestRaw: Uint8List(0),
    responseRaw: response.toJson(),
    createdAt: createdAt ?? DateTime.parse('2024-01-01T12:00:00Z'),
  );
}
