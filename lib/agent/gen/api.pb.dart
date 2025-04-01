//
//  Generated code. Do not modify.
//  source: api.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

enum Flow_Request {
  httpRequest, 
  grpcRequest, 
  sqlQuery, 
  notSet
}

enum Flow_Response {
  httpResponse, 
  grpcResponse, 
  sqlResponse, 
  notSet
}

class Flow extends $pb.GeneratedMessage {
  factory Flow({
    $core.String? uuid,
    $core.String? sourceAddr,
    $core.String? destAddr,
    $core.String? l4Protocol,
    $core.String? l7Protocol,
    HTTPRequest? httpRequest,
    GRPCRequest? grpcRequest,
    SQLQuery? sqlQuery,
    HTTPResponse? httpResponse,
    GRPCResponse? grpcResponse,
    SQLResponse? sqlResponse,
  }) {
    final $result = create();
    if (uuid != null) {
      $result.uuid = uuid;
    }
    if (sourceAddr != null) {
      $result.sourceAddr = sourceAddr;
    }
    if (destAddr != null) {
      $result.destAddr = destAddr;
    }
    if (l4Protocol != null) {
      $result.l4Protocol = l4Protocol;
    }
    if (l7Protocol != null) {
      $result.l7Protocol = l7Protocol;
    }
    if (httpRequest != null) {
      $result.httpRequest = httpRequest;
    }
    if (grpcRequest != null) {
      $result.grpcRequest = grpcRequest;
    }
    if (sqlQuery != null) {
      $result.sqlQuery = sqlQuery;
    }
    if (httpResponse != null) {
      $result.httpResponse = httpResponse;
    }
    if (grpcResponse != null) {
      $result.grpcResponse = grpcResponse;
    }
    if (sqlResponse != null) {
      $result.sqlResponse = sqlResponse;
    }
    return $result;
  }
  Flow._() : super();
  factory Flow.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Flow.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Flow_Request> _Flow_RequestByTag = {
    6 : Flow_Request.httpRequest,
    7 : Flow_Request.grpcRequest,
    8 : Flow_Request.sqlQuery,
    0 : Flow_Request.notSet
  };
  static const $core.Map<$core.int, Flow_Response> _Flow_ResponseByTag = {
    9 : Flow_Response.httpResponse,
    10 : Flow_Response.grpcResponse,
    11 : Flow_Response.sqlResponse,
    0 : Flow_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Flow', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..oo(0, [6, 7, 8])
    ..oo(1, [9, 10, 11])
    ..aOS(1, _omitFieldNames ? '' : 'uuid')
    ..aOS(2, _omitFieldNames ? '' : 'sourceAddr')
    ..aOS(3, _omitFieldNames ? '' : 'destAddr')
    ..aOS(4, _omitFieldNames ? '' : 'l4Protocol')
    ..aOS(5, _omitFieldNames ? '' : 'l7Protocol')
    ..aOM<HTTPRequest>(6, _omitFieldNames ? '' : 'httpRequest', subBuilder: HTTPRequest.create)
    ..aOM<GRPCRequest>(7, _omitFieldNames ? '' : 'grpcRequest', subBuilder: GRPCRequest.create)
    ..aOM<SQLQuery>(8, _omitFieldNames ? '' : 'sqlQuery', subBuilder: SQLQuery.create)
    ..aOM<HTTPResponse>(9, _omitFieldNames ? '' : 'httpResponse', subBuilder: HTTPResponse.create)
    ..aOM<GRPCResponse>(10, _omitFieldNames ? '' : 'grpcResponse', subBuilder: GRPCResponse.create)
    ..aOM<SQLResponse>(11, _omitFieldNames ? '' : 'sqlResponse', subBuilder: SQLResponse.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Flow clone() => Flow()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Flow copyWith(void Function(Flow) updates) => super.copyWith((message) => updates(message as Flow)) as Flow;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Flow create() => Flow._();
  Flow createEmptyInstance() => create();
  static $pb.PbList<Flow> createRepeated() => $pb.PbList<Flow>();
  @$core.pragma('dart2js:noInline')
  static Flow getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Flow>(create);
  static Flow? _defaultInstance;

  Flow_Request whichRequest() => _Flow_RequestByTag[$_whichOneof(0)]!;
  void clearRequest() => clearField($_whichOneof(0));

  Flow_Response whichResponse() => _Flow_ResponseByTag[$_whichOneof(1)]!;
  void clearResponse() => clearField($_whichOneof(1));

  @$pb.TagNumber(1)
  $core.String get uuid => $_getSZ(0);
  @$pb.TagNumber(1)
  set uuid($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUuid() => $_has(0);
  @$pb.TagNumber(1)
  void clearUuid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get sourceAddr => $_getSZ(1);
  @$pb.TagNumber(2)
  set sourceAddr($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSourceAddr() => $_has(1);
  @$pb.TagNumber(2)
  void clearSourceAddr() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get destAddr => $_getSZ(2);
  @$pb.TagNumber(3)
  set destAddr($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDestAddr() => $_has(2);
  @$pb.TagNumber(3)
  void clearDestAddr() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get l4Protocol => $_getSZ(3);
  @$pb.TagNumber(4)
  set l4Protocol($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasL4Protocol() => $_has(3);
  @$pb.TagNumber(4)
  void clearL4Protocol() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get l7Protocol => $_getSZ(4);
  @$pb.TagNumber(5)
  set l7Protocol($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasL7Protocol() => $_has(4);
  @$pb.TagNumber(5)
  void clearL7Protocol() => clearField(5);

  @$pb.TagNumber(6)
  HTTPRequest get httpRequest => $_getN(5);
  @$pb.TagNumber(6)
  set httpRequest(HTTPRequest v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasHttpRequest() => $_has(5);
  @$pb.TagNumber(6)
  void clearHttpRequest() => clearField(6);
  @$pb.TagNumber(6)
  HTTPRequest ensureHttpRequest() => $_ensure(5);

  @$pb.TagNumber(7)
  GRPCRequest get grpcRequest => $_getN(6);
  @$pb.TagNumber(7)
  set grpcRequest(GRPCRequest v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasGrpcRequest() => $_has(6);
  @$pb.TagNumber(7)
  void clearGrpcRequest() => clearField(7);
  @$pb.TagNumber(7)
  GRPCRequest ensureGrpcRequest() => $_ensure(6);

  @$pb.TagNumber(8)
  SQLQuery get sqlQuery => $_getN(7);
  @$pb.TagNumber(8)
  set sqlQuery(SQLQuery v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasSqlQuery() => $_has(7);
  @$pb.TagNumber(8)
  void clearSqlQuery() => clearField(8);
  @$pb.TagNumber(8)
  SQLQuery ensureSqlQuery() => $_ensure(7);

  @$pb.TagNumber(9)
  HTTPResponse get httpResponse => $_getN(8);
  @$pb.TagNumber(9)
  set httpResponse(HTTPResponse v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasHttpResponse() => $_has(8);
  @$pb.TagNumber(9)
  void clearHttpResponse() => clearField(9);
  @$pb.TagNumber(9)
  HTTPResponse ensureHttpResponse() => $_ensure(8);

  @$pb.TagNumber(10)
  GRPCResponse get grpcResponse => $_getN(9);
  @$pb.TagNumber(10)
  set grpcResponse(GRPCResponse v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasGrpcResponse() => $_has(9);
  @$pb.TagNumber(10)
  void clearGrpcResponse() => clearField(10);
  @$pb.TagNumber(10)
  GRPCResponse ensureGrpcResponse() => $_ensure(9);

  @$pb.TagNumber(11)
  SQLResponse get sqlResponse => $_getN(10);
  @$pb.TagNumber(11)
  set sqlResponse(SQLResponse v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasSqlResponse() => $_has(10);
  @$pb.TagNumber(11)
  void clearSqlResponse() => clearField(11);
  @$pb.TagNumber(11)
  SQLResponse ensureSqlResponse() => $_ensure(10);
}

class Flows extends $pb.GeneratedMessage {
  factory Flows({
    $core.Iterable<Flow>? flows,
  }) {
    final $result = create();
    if (flows != null) {
      $result.flows.addAll(flows);
    }
    return $result;
  }
  Flows._() : super();
  factory Flows.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Flows.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Flows', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..pc<Flow>(1, _omitFieldNames ? '' : 'flows', $pb.PbFieldType.PM, subBuilder: Flow.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Flows clone() => Flows()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Flows copyWith(void Function(Flows) updates) => super.copyWith((message) => updates(message as Flows)) as Flows;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Flows create() => Flows._();
  Flows createEmptyInstance() => create();
  static $pb.PbList<Flows> createRepeated() => $pb.PbList<Flows>();
  @$core.pragma('dart2js:noInline')
  static Flows getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Flows>(create);
  static Flows? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Flow> get flows => $_getList(0);
}

class StringList extends $pb.GeneratedMessage {
  factory StringList({
    $core.Iterable<$core.String>? values,
  }) {
    final $result = create();
    if (values != null) {
      $result.values.addAll(values);
    }
    return $result;
  }
  StringList._() : super();
  factory StringList.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StringList.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StringList', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'values')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StringList clone() => StringList()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StringList copyWith(void Function(StringList) updates) => super.copyWith((message) => updates(message as StringList)) as StringList;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StringList create() => StringList._();
  StringList createEmptyInstance() => create();
  static $pb.PbList<StringList> createRepeated() => $pb.PbList<StringList>();
  @$core.pragma('dart2js:noInline')
  static StringList getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StringList>(create);
  static StringList? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get values => $_getList(0);
}

class HTTPRequest extends $pb.GeneratedMessage {
  factory HTTPRequest({
    $core.String? method,
    $core.String? host,
    $core.String? path,
    $core.String? httpVersion,
    $core.Map<$core.String, StringList>? headers,
    $core.List<$core.int>? payload,
  }) {
    final $result = create();
    if (method != null) {
      $result.method = method;
    }
    if (host != null) {
      $result.host = host;
    }
    if (path != null) {
      $result.path = path;
    }
    if (httpVersion != null) {
      $result.httpVersion = httpVersion;
    }
    if (headers != null) {
      $result.headers.addAll(headers);
    }
    if (payload != null) {
      $result.payload = payload;
    }
    return $result;
  }
  HTTPRequest._() : super();
  factory HTTPRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HTTPRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HTTPRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'method')
    ..aOS(2, _omitFieldNames ? '' : 'host')
    ..aOS(3, _omitFieldNames ? '' : 'path')
    ..aOS(4, _omitFieldNames ? '' : 'httpVersion')
    ..m<$core.String, StringList>(5, _omitFieldNames ? '' : 'headers', entryClassName: 'HTTPRequest.HeadersEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: StringList.create, valueDefaultOrMaker: StringList.getDefault, packageName: const $pb.PackageName('api'))
    ..a<$core.List<$core.int>>(6, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HTTPRequest clone() => HTTPRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HTTPRequest copyWith(void Function(HTTPRequest) updates) => super.copyWith((message) => updates(message as HTTPRequest)) as HTTPRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HTTPRequest create() => HTTPRequest._();
  HTTPRequest createEmptyInstance() => create();
  static $pb.PbList<HTTPRequest> createRepeated() => $pb.PbList<HTTPRequest>();
  @$core.pragma('dart2js:noInline')
  static HTTPRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HTTPRequest>(create);
  static HTTPRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get method => $_getSZ(0);
  @$pb.TagNumber(1)
  set method($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMethod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMethod() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get host => $_getSZ(1);
  @$pb.TagNumber(2)
  set host($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasHost() => $_has(1);
  @$pb.TagNumber(2)
  void clearHost() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get path => $_getSZ(2);
  @$pb.TagNumber(3)
  set path($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPath() => $_has(2);
  @$pb.TagNumber(3)
  void clearPath() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get httpVersion => $_getSZ(3);
  @$pb.TagNumber(4)
  set httpVersion($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasHttpVersion() => $_has(3);
  @$pb.TagNumber(4)
  void clearHttpVersion() => clearField(4);

  @$pb.TagNumber(5)
  $core.Map<$core.String, StringList> get headers => $_getMap(4);

  @$pb.TagNumber(6)
  $core.List<$core.int> get payload => $_getN(5);
  @$pb.TagNumber(6)
  set payload($core.List<$core.int> v) { $_setBytes(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasPayload() => $_has(5);
  @$pb.TagNumber(6)
  void clearPayload() => clearField(6);
}

class HTTPResponse extends $pb.GeneratedMessage {
  factory HTTPResponse({
    $core.String? httpVersion,
    $core.int? status,
    $core.String? statusMsg,
    $core.Map<$core.String, StringList>? headers,
    $core.List<$core.int>? payload,
  }) {
    final $result = create();
    if (httpVersion != null) {
      $result.httpVersion = httpVersion;
    }
    if (status != null) {
      $result.status = status;
    }
    if (statusMsg != null) {
      $result.statusMsg = statusMsg;
    }
    if (headers != null) {
      $result.headers.addAll(headers);
    }
    if (payload != null) {
      $result.payload = payload;
    }
    return $result;
  }
  HTTPResponse._() : super();
  factory HTTPResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HTTPResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HTTPResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'httpVersion')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'status', $pb.PbFieldType.O3)
    ..aOS(3, _omitFieldNames ? '' : 'statusMsg')
    ..m<$core.String, StringList>(4, _omitFieldNames ? '' : 'headers', entryClassName: 'HTTPResponse.HeadersEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: StringList.create, valueDefaultOrMaker: StringList.getDefault, packageName: const $pb.PackageName('api'))
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HTTPResponse clone() => HTTPResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HTTPResponse copyWith(void Function(HTTPResponse) updates) => super.copyWith((message) => updates(message as HTTPResponse)) as HTTPResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HTTPResponse create() => HTTPResponse._();
  HTTPResponse createEmptyInstance() => create();
  static $pb.PbList<HTTPResponse> createRepeated() => $pb.PbList<HTTPResponse>();
  @$core.pragma('dart2js:noInline')
  static HTTPResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HTTPResponse>(create);
  static HTTPResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get httpVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set httpVersion($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHttpVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearHttpVersion() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get status => $_getIZ(1);
  @$pb.TagNumber(2)
  set status($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasStatus() => $_has(1);
  @$pb.TagNumber(2)
  void clearStatus() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get statusMsg => $_getSZ(2);
  @$pb.TagNumber(3)
  set statusMsg($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasStatusMsg() => $_has(2);
  @$pb.TagNumber(3)
  void clearStatusMsg() => clearField(3);

  @$pb.TagNumber(4)
  $core.Map<$core.String, StringList> get headers => $_getMap(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get payload => $_getN(4);
  @$pb.TagNumber(5)
  set payload($core.List<$core.int> v) { $_setBytes(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPayload() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayload() => clearField(5);
}

class GRPCRequest extends $pb.GeneratedMessage {
  factory GRPCRequest({
    $core.String? path,
    $core.Map<$core.String, StringList>? headers,
    $core.List<$core.int>? payload,
  }) {
    final $result = create();
    if (path != null) {
      $result.path = path;
    }
    if (headers != null) {
      $result.headers.addAll(headers);
    }
    if (payload != null) {
      $result.payload = payload;
    }
    return $result;
  }
  GRPCRequest._() : super();
  factory GRPCRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GRPCRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GRPCRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'path')
    ..m<$core.String, StringList>(2, _omitFieldNames ? '' : 'headers', entryClassName: 'GRPCRequest.HeadersEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: StringList.create, valueDefaultOrMaker: StringList.getDefault, packageName: const $pb.PackageName('api'))
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GRPCRequest clone() => GRPCRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GRPCRequest copyWith(void Function(GRPCRequest) updates) => super.copyWith((message) => updates(message as GRPCRequest)) as GRPCRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GRPCRequest create() => GRPCRequest._();
  GRPCRequest createEmptyInstance() => create();
  static $pb.PbList<GRPCRequest> createRepeated() => $pb.PbList<GRPCRequest>();
  @$core.pragma('dart2js:noInline')
  static GRPCRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GRPCRequest>(create);
  static GRPCRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get path => $_getSZ(0);
  @$pb.TagNumber(1)
  set path($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPath() => $_has(0);
  @$pb.TagNumber(1)
  void clearPath() => clearField(1);

  @$pb.TagNumber(2)
  $core.Map<$core.String, StringList> get headers => $_getMap(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get payload => $_getN(2);
  @$pb.TagNumber(3)
  set payload($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => clearField(3);
}

class GRPCResponse extends $pb.GeneratedMessage {
  factory GRPCResponse({
    $core.Map<$core.String, StringList>? headers,
    $core.List<$core.int>? payload,
  }) {
    final $result = create();
    if (headers != null) {
      $result.headers.addAll(headers);
    }
    if (payload != null) {
      $result.payload = payload;
    }
    return $result;
  }
  GRPCResponse._() : super();
  factory GRPCResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GRPCResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GRPCResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..m<$core.String, StringList>(1, _omitFieldNames ? '' : 'headers', entryClassName: 'GRPCResponse.HeadersEntry', keyFieldType: $pb.PbFieldType.OS, valueFieldType: $pb.PbFieldType.OM, valueCreator: StringList.create, valueDefaultOrMaker: StringList.getDefault, packageName: const $pb.PackageName('api'))
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GRPCResponse clone() => GRPCResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GRPCResponse copyWith(void Function(GRPCResponse) updates) => super.copyWith((message) => updates(message as GRPCResponse)) as GRPCResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GRPCResponse create() => GRPCResponse._();
  GRPCResponse createEmptyInstance() => create();
  static $pb.PbList<GRPCResponse> createRepeated() => $pb.PbList<GRPCResponse>();
  @$core.pragma('dart2js:noInline')
  static GRPCResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GRPCResponse>(create);
  static GRPCResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.Map<$core.String, StringList> get headers => $_getMap(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get payload => $_getN(1);
  @$pb.TagNumber(2)
  set payload($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => clearField(2);
}

class SQLQuery extends $pb.GeneratedMessage {
  factory SQLQuery({
    $core.String? query,
    StringList? params,
  }) {
    final $result = create();
    if (query != null) {
      $result.query = query;
    }
    if (params != null) {
      $result.params = params;
    }
    return $result;
  }
  SQLQuery._() : super();
  factory SQLQuery.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SQLQuery.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SQLQuery', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'query')
    ..aOM<StringList>(2, _omitFieldNames ? '' : 'params', subBuilder: StringList.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SQLQuery clone() => SQLQuery()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SQLQuery copyWith(void Function(SQLQuery) updates) => super.copyWith((message) => updates(message as SQLQuery)) as SQLQuery;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SQLQuery create() => SQLQuery._();
  SQLQuery createEmptyInstance() => create();
  static $pb.PbList<SQLQuery> createRepeated() => $pb.PbList<SQLQuery>();
  @$core.pragma('dart2js:noInline')
  static SQLQuery getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SQLQuery>(create);
  static SQLQuery? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get query => $_getSZ(0);
  @$pb.TagNumber(1)
  set query($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasQuery() => $_has(0);
  @$pb.TagNumber(1)
  void clearQuery() => clearField(1);

  @$pb.TagNumber(2)
  StringList get params => $_getN(1);
  @$pb.TagNumber(2)
  set params(StringList v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasParams() => $_has(1);
  @$pb.TagNumber(2)
  void clearParams() => clearField(2);
  @$pb.TagNumber(2)
  StringList ensureParams() => $_ensure(1);
}

class SQLResponse extends $pb.GeneratedMessage {
  factory SQLResponse({
    StringList? columns,
    $core.Iterable<StringList>? rows,
  }) {
    final $result = create();
    if (columns != null) {
      $result.columns = columns;
    }
    if (rows != null) {
      $result.rows.addAll(rows);
    }
    return $result;
  }
  SQLResponse._() : super();
  factory SQLResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SQLResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SQLResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOM<StringList>(1, _omitFieldNames ? '' : 'columns', subBuilder: StringList.create)
    ..pc<StringList>(2, _omitFieldNames ? '' : 'rows', $pb.PbFieldType.PM, subBuilder: StringList.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SQLResponse clone() => SQLResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SQLResponse copyWith(void Function(SQLResponse) updates) => super.copyWith((message) => updates(message as SQLResponse)) as SQLResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SQLResponse create() => SQLResponse._();
  SQLResponse createEmptyInstance() => create();
  static $pb.PbList<SQLResponse> createRepeated() => $pb.PbList<SQLResponse>();
  @$core.pragma('dart2js:noInline')
  static SQLResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SQLResponse>(create);
  static SQLResponse? _defaultInstance;

  @$pb.TagNumber(1)
  StringList get columns => $_getN(0);
  @$pb.TagNumber(1)
  set columns(StringList v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasColumns() => $_has(0);
  @$pb.TagNumber(1)
  void clearColumns() => clearField(1);
  @$pb.TagNumber(1)
  StringList ensureColumns() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<StringList> get rows => $_getList(1);
}

class Reply extends $pb.GeneratedMessage {
  factory Reply({
    $core.String? status,
  }) {
    final $result = create();
    if (status != null) {
      $result.status = status;
    }
    return $result;
  }
  Reply._() : super();
  factory Reply.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Reply.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Reply', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Reply clone() => Reply()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Reply copyWith(void Function(Reply) updates) => super.copyWith((message) => updates(message as Reply)) as Reply;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Reply create() => Reply._();
  Reply createEmptyInstance() => create();
  static $pb.PbList<Reply> createRepeated() => $pb.PbList<Reply>();
  @$core.pragma('dart2js:noInline')
  static Reply getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Reply>(create);
  static Reply? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => clearField(1);
}

class AgentStarted extends $pb.GeneratedMessage {
  factory AgentStarted({
    $core.String? version,
  }) {
    final $result = create();
    if (version != null) {
      $result.version = version;
    }
    return $result;
  }
  AgentStarted._() : super();
  factory AgentStarted.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AgentStarted.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AgentStarted', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AgentStarted clone() => AgentStarted()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AgentStarted copyWith(void Function(AgentStarted) updates) => super.copyWith((message) => updates(message as AgentStarted)) as AgentStarted;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgentStarted create() => AgentStarted._();
  AgentStarted createEmptyInstance() => create();
  static $pb.PbList<AgentStarted> createRepeated() => $pb.PbList<AgentStarted>();
  @$core.pragma('dart2js:noInline')
  static AgentStarted getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AgentStarted>(create);
  static AgentStarted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get version => $_getSZ(0);
  @$pb.TagNumber(1)
  set version($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => clearField(1);
}

class AgentVerified extends $pb.GeneratedMessage {
  factory AgentVerified({
    $core.bool? valid,
    $core.String? message,
  }) {
    final $result = create();
    if (valid != null) {
      $result.valid = valid;
    }
    if (message != null) {
      $result.message = message;
    }
    return $result;
  }
  AgentVerified._() : super();
  factory AgentVerified.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AgentVerified.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AgentVerified', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'valid')
    ..aOS(2, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AgentVerified clone() => AgentVerified()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AgentVerified copyWith(void Function(AgentVerified) updates) => super.copyWith((message) => updates(message as AgentVerified)) as AgentVerified;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AgentVerified create() => AgentVerified._();
  AgentVerified createEmptyInstance() => create();
  static $pb.PbList<AgentVerified> createRepeated() => $pb.PbList<AgentVerified>();
  @$core.pragma('dart2js:noInline')
  static AgentVerified getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AgentVerified>(create);
  static AgentVerified? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get valid => $_getBF(0);
  @$pb.TagNumber(1)
  set valid($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValid() => $_has(0);
  @$pb.TagNumber(1)
  void clearValid() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get message => $_getSZ(1);
  @$pb.TagNumber(2)
  set message($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessage() => clearField(2);
}

class Command extends $pb.GeneratedMessage {
  factory Command({
    $core.String? type,
    Settings? settings,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (settings != null) {
      $result.settings = settings;
    }
    return $result;
  }
  Command._() : super();
  factory Command.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Command.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Command', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'type')
    ..aOM<Settings>(2, _omitFieldNames ? '' : 'settings', subBuilder: Settings.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Command clone() => Command()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Command copyWith(void Function(Command) updates) => super.copyWith((message) => updates(message as Command)) as Command;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Command create() => Command._();
  Command createEmptyInstance() => create();
  static $pb.PbList<Command> createRepeated() => $pb.PbList<Command>();
  @$core.pragma('dart2js:noInline')
  static Command getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Command>(create);
  static Command? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get type => $_getSZ(0);
  @$pb.TagNumber(1)
  set type($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  Settings get settings => $_getN(1);
  @$pb.TagNumber(2)
  set settings(Settings v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasSettings() => $_has(1);
  @$pb.TagNumber(2)
  void clearSettings() => clearField(2);
  @$pb.TagNumber(2)
  Settings ensureSettings() => $_ensure(1);
}

class Settings extends $pb.GeneratedMessage {
  factory Settings({
    $core.Iterable<$core.String>? containerIds,
    $core.String? licenseKey,
  }) {
    final $result = create();
    if (containerIds != null) {
      $result.containerIds.addAll(containerIds);
    }
    if (licenseKey != null) {
      $result.licenseKey = licenseKey;
    }
    return $result;
  }
  Settings._() : super();
  factory Settings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Settings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Settings', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'containerIds')
    ..aOS(2, _omitFieldNames ? '' : 'licenseKey')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Settings clone() => Settings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Settings copyWith(void Function(Settings) updates) => super.copyWith((message) => updates(message as Settings)) as Settings;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Settings create() => Settings._();
  Settings createEmptyInstance() => create();
  static $pb.PbList<Settings> createRepeated() => $pb.PbList<Settings>();
  @$core.pragma('dart2js:noInline')
  static Settings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Settings>(create);
  static Settings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get containerIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.String get licenseKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set licenseKey($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLicenseKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearLicenseKey() => clearField(2);
}

class Request extends $pb.GeneratedMessage {
  factory Request({
    $core.int? num,
  }) {
    final $result = create();
    if (num != null) {
      $result.num = num;
    }
    return $result;
  }
  Request._() : super();
  factory Request.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Request.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Request', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'num', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Request clone() => Request()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Request copyWith(void Function(Request) updates) => super.copyWith((message) => updates(message as Request)) as Request;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Request create() => Request._();
  Request createEmptyInstance() => create();
  static $pb.PbList<Request> createRepeated() => $pb.PbList<Request>();
  @$core.pragma('dart2js:noInline')
  static Request getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Request>(create);
  static Request? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get num => $_getIZ(0);
  @$pb.TagNumber(1)
  set num($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNum() => $_has(0);
  @$pb.TagNumber(1)
  void clearNum() => clearField(1);
}

class Response extends $pb.GeneratedMessage {
  factory Response({
    $core.int? result,
  }) {
    final $result = create();
    if (result != null) {
      $result.result = result;
    }
    return $result;
  }
  Response._() : super();
  factory Response.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'result', $pb.PbFieldType.O3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response clone() => Response()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response copyWith(void Function(Response) updates) => super.copyWith((message) => updates(message as Response)) as Response;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response create() => Response._();
  Response createEmptyInstance() => create();
  static $pb.PbList<Response> createRepeated() => $pb.PbList<Response>();
  @$core.pragma('dart2js:noInline')
  static Response getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response>(create);
  static Response? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get result => $_getIZ(0);
  @$pb.TagNumber(1)
  set result($core.int v) { $_setSignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasResult() => $_has(0);
  @$pb.TagNumber(1)
  void clearResult() => clearField(1);
}

class Container extends $pb.GeneratedMessage {
  factory Container({
    $core.String? id,
    $core.String? image,
    $core.String? ip,
    $core.String? name,
    $core.String? status,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (image != null) {
      $result.image = image;
    }
    if (ip != null) {
      $result.ip = ip;
    }
    if (name != null) {
      $result.name = name;
    }
    if (status != null) {
      $result.status = status;
    }
    return $result;
  }
  Container._() : super();
  factory Container.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Container.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Container', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'image')
    ..aOS(3, _omitFieldNames ? '' : 'ip')
    ..aOS(4, _omitFieldNames ? '' : 'name')
    ..aOS(5, _omitFieldNames ? '' : 'status')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Container clone() => Container()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Container copyWith(void Function(Container) updates) => super.copyWith((message) => updates(message as Container)) as Container;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Container create() => Container._();
  Container createEmptyInstance() => create();
  static $pb.PbList<Container> createRepeated() => $pb.PbList<Container>();
  @$core.pragma('dart2js:noInline')
  static Container getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Container>(create);
  static Container? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get image => $_getSZ(1);
  @$pb.TagNumber(2)
  set image($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasImage() => $_has(1);
  @$pb.TagNumber(2)
  void clearImage() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get ip => $_getSZ(2);
  @$pb.TagNumber(3)
  set ip($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasIp() => $_has(2);
  @$pb.TagNumber(3)
  void clearIp() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get name => $_getSZ(3);
  @$pb.TagNumber(4)
  set name($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasName() => $_has(3);
  @$pb.TagNumber(4)
  void clearName() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get status => $_getSZ(4);
  @$pb.TagNumber(5)
  set status($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasStatus() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatus() => clearField(5);
}

class Containers extends $pb.GeneratedMessage {
  factory Containers({
    $core.Iterable<Container>? containers,
  }) {
    final $result = create();
    if (containers != null) {
      $result.containers.addAll(containers);
    }
    return $result;
  }
  Containers._() : super();
  factory Containers.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Containers.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Containers', package: const $pb.PackageName(_omitMessageNames ? '' : 'api'), createEmptyInstance: create)
    ..pc<Container>(1, _omitFieldNames ? '' : 'containers', $pb.PbFieldType.PM, subBuilder: Container.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Containers clone() => Containers()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Containers copyWith(void Function(Containers) updates) => super.copyWith((message) => updates(message as Containers)) as Containers;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Containers create() => Containers._();
  Containers createEmptyInstance() => create();
  static $pb.PbList<Containers> createRepeated() => $pb.PbList<Containers>();
  @$core.pragma('dart2js:noInline')
  static Containers getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Containers>(create);
  static Containers? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Container> get containers => $_getList(0);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
