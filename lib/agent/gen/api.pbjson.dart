//
//  Generated code. Do not modify.
//  source: api.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use flowDescriptor instead')
const Flow$json = {
  '1': 'Flow',
  '2': [
    {'1': 'uuid', '3': 1, '4': 1, '5': 9, '10': 'uuid'},
    {'1': 'source_addr', '3': 2, '4': 1, '5': 9, '10': 'sourceAddr'},
    {'1': 'dest_addr', '3': 3, '4': 1, '5': 9, '10': 'destAddr'},
    {'1': 'l4_protocol', '3': 4, '4': 1, '5': 9, '10': 'l4Protocol'},
    {'1': 'l7_protocol', '3': 5, '4': 1, '5': 9, '10': 'l7Protocol'},
    {'1': 'http_request', '3': 6, '4': 1, '5': 11, '6': '.api.HTTPRequest', '9': 0, '10': 'httpRequest'},
    {'1': 'grpc_request', '3': 7, '4': 1, '5': 11, '6': '.api.GRPCRequest', '9': 0, '10': 'grpcRequest'},
    {'1': 'sql_query', '3': 8, '4': 1, '5': 11, '6': '.api.SQLQuery', '9': 0, '10': 'sqlQuery'},
    {'1': 'http_response', '3': 9, '4': 1, '5': 11, '6': '.api.HTTPResponse', '9': 1, '10': 'httpResponse'},
    {'1': 'grpc_response', '3': 10, '4': 1, '5': 11, '6': '.api.GRPCResponse', '9': 1, '10': 'grpcResponse'},
    {'1': 'sql_response', '3': 11, '4': 1, '5': 11, '6': '.api.SQLResponse', '9': 1, '10': 'sqlResponse'},
  ],
  '8': [
    {'1': 'request'},
    {'1': 'response'},
  ],
};

/// Descriptor for `Flow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flowDescriptor = $convert.base64Decode(
    'CgRGbG93EhIKBHV1aWQYASABKAlSBHV1aWQSHwoLc291cmNlX2FkZHIYAiABKAlSCnNvdXJjZU'
    'FkZHISGwoJZGVzdF9hZGRyGAMgASgJUghkZXN0QWRkchIfCgtsNF9wcm90b2NvbBgEIAEoCVIK'
    'bDRQcm90b2NvbBIfCgtsN19wcm90b2NvbBgFIAEoCVIKbDdQcm90b2NvbBI1CgxodHRwX3JlcX'
    'Vlc3QYBiABKAsyEC5hcGkuSFRUUFJlcXVlc3RIAFILaHR0cFJlcXVlc3QSNQoMZ3JwY19yZXF1'
    'ZXN0GAcgASgLMhAuYXBpLkdSUENSZXF1ZXN0SABSC2dycGNSZXF1ZXN0EiwKCXNxbF9xdWVyeR'
    'gIIAEoCzINLmFwaS5TUUxRdWVyeUgAUghzcWxRdWVyeRI4Cg1odHRwX3Jlc3BvbnNlGAkgASgL'
    'MhEuYXBpLkhUVFBSZXNwb25zZUgBUgxodHRwUmVzcG9uc2USOAoNZ3JwY19yZXNwb25zZRgKIA'
    'EoCzIRLmFwaS5HUlBDUmVzcG9uc2VIAVIMZ3JwY1Jlc3BvbnNlEjUKDHNxbF9yZXNwb25zZRgL'
    'IAEoCzIQLmFwaS5TUUxSZXNwb25zZUgBUgtzcWxSZXNwb25zZUIJCgdyZXF1ZXN0QgoKCHJlc3'
    'BvbnNl');

@$core.Deprecated('Use flowsDescriptor instead')
const Flows$json = {
  '1': 'Flows',
  '2': [
    {'1': 'flows', '3': 1, '4': 3, '5': 11, '6': '.api.Flow', '10': 'flows'},
  ],
};

/// Descriptor for `Flows`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List flowsDescriptor = $convert.base64Decode(
    'CgVGbG93cxIfCgVmbG93cxgBIAMoCzIJLmFwaS5GbG93UgVmbG93cw==');

@$core.Deprecated('Use stringListDescriptor instead')
const StringList$json = {
  '1': 'StringList',
  '2': [
    {'1': 'values', '3': 1, '4': 3, '5': 9, '10': 'values'},
  ],
};

/// Descriptor for `StringList`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stringListDescriptor = $convert.base64Decode(
    'CgpTdHJpbmdMaXN0EhYKBnZhbHVlcxgBIAMoCVIGdmFsdWVz');

@$core.Deprecated('Use hTTPRequestDescriptor instead')
const HTTPRequest$json = {
  '1': 'HTTPRequest',
  '2': [
    {'1': 'method', '3': 1, '4': 1, '5': 9, '10': 'method'},
    {'1': 'host', '3': 2, '4': 1, '5': 9, '10': 'host'},
    {'1': 'path', '3': 3, '4': 1, '5': 9, '10': 'path'},
    {'1': 'http_version', '3': 4, '4': 1, '5': 9, '10': 'httpVersion'},
    {'1': 'headers', '3': 5, '4': 3, '5': 11, '6': '.api.HTTPRequest.HeadersEntry', '10': 'headers'},
    {'1': 'payload', '3': 6, '4': 1, '5': 12, '10': 'payload'},
  ],
  '3': [HTTPRequest_HeadersEntry$json],
};

@$core.Deprecated('Use hTTPRequestDescriptor instead')
const HTTPRequest_HeadersEntry$json = {
  '1': 'HeadersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.api.StringList', '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `HTTPRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hTTPRequestDescriptor = $convert.base64Decode(
    'CgtIVFRQUmVxdWVzdBIWCgZtZXRob2QYASABKAlSBm1ldGhvZBISCgRob3N0GAIgASgJUgRob3'
    'N0EhIKBHBhdGgYAyABKAlSBHBhdGgSIQoMaHR0cF92ZXJzaW9uGAQgASgJUgtodHRwVmVyc2lv'
    'bhI3CgdoZWFkZXJzGAUgAygLMh0uYXBpLkhUVFBSZXF1ZXN0LkhlYWRlcnNFbnRyeVIHaGVhZG'
    'VycxIYCgdwYXlsb2FkGAYgASgMUgdwYXlsb2FkGksKDEhlYWRlcnNFbnRyeRIQCgNrZXkYASAB'
    'KAlSA2tleRIlCgV2YWx1ZRgCIAEoCzIPLmFwaS5TdHJpbmdMaXN0UgV2YWx1ZToCOAE=');

@$core.Deprecated('Use hTTPResponseDescriptor instead')
const HTTPResponse$json = {
  '1': 'HTTPResponse',
  '2': [
    {'1': 'http_version', '3': 1, '4': 1, '5': 9, '10': 'httpVersion'},
    {'1': 'status', '3': 2, '4': 1, '5': 5, '10': 'status'},
    {'1': 'status_msg', '3': 3, '4': 1, '5': 9, '10': 'statusMsg'},
    {'1': 'headers', '3': 4, '4': 3, '5': 11, '6': '.api.HTTPResponse.HeadersEntry', '10': 'headers'},
    {'1': 'payload', '3': 5, '4': 1, '5': 12, '10': 'payload'},
  ],
  '3': [HTTPResponse_HeadersEntry$json],
};

@$core.Deprecated('Use hTTPResponseDescriptor instead')
const HTTPResponse_HeadersEntry$json = {
  '1': 'HeadersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.api.StringList', '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `HTTPResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hTTPResponseDescriptor = $convert.base64Decode(
    'CgxIVFRQUmVzcG9uc2USIQoMaHR0cF92ZXJzaW9uGAEgASgJUgtodHRwVmVyc2lvbhIWCgZzdG'
    'F0dXMYAiABKAVSBnN0YXR1cxIdCgpzdGF0dXNfbXNnGAMgASgJUglzdGF0dXNNc2cSOAoHaGVh'
    'ZGVycxgEIAMoCzIeLmFwaS5IVFRQUmVzcG9uc2UuSGVhZGVyc0VudHJ5UgdoZWFkZXJzEhgKB3'
    'BheWxvYWQYBSABKAxSB3BheWxvYWQaSwoMSGVhZGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5'
    'EiUKBXZhbHVlGAIgASgLMg8uYXBpLlN0cmluZ0xpc3RSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use gRPCRequestDescriptor instead')
const GRPCRequest$json = {
  '1': 'GRPCRequest',
  '2': [
    {'1': 'path', '3': 1, '4': 1, '5': 9, '10': 'path'},
    {'1': 'headers', '3': 2, '4': 3, '5': 11, '6': '.api.GRPCRequest.HeadersEntry', '10': 'headers'},
    {'1': 'payload', '3': 3, '4': 1, '5': 12, '10': 'payload'},
  ],
  '3': [GRPCRequest_HeadersEntry$json],
};

@$core.Deprecated('Use gRPCRequestDescriptor instead')
const GRPCRequest_HeadersEntry$json = {
  '1': 'HeadersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.api.StringList', '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `GRPCRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gRPCRequestDescriptor = $convert.base64Decode(
    'CgtHUlBDUmVxdWVzdBISCgRwYXRoGAEgASgJUgRwYXRoEjcKB2hlYWRlcnMYAiADKAsyHS5hcG'
    'kuR1JQQ1JlcXVlc3QuSGVhZGVyc0VudHJ5UgdoZWFkZXJzEhgKB3BheWxvYWQYAyABKAxSB3Bh'
    'eWxvYWQaSwoMSGVhZGVyc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EiUKBXZhbHVlGAIgASgLMg'
    '8uYXBpLlN0cmluZ0xpc3RSBXZhbHVlOgI4AQ==');

@$core.Deprecated('Use gRPCResponseDescriptor instead')
const GRPCResponse$json = {
  '1': 'GRPCResponse',
  '2': [
    {'1': 'headers', '3': 1, '4': 3, '5': 11, '6': '.api.GRPCResponse.HeadersEntry', '10': 'headers'},
    {'1': 'payload', '3': 2, '4': 1, '5': 12, '10': 'payload'},
  ],
  '3': [GRPCResponse_HeadersEntry$json],
};

@$core.Deprecated('Use gRPCResponseDescriptor instead')
const GRPCResponse_HeadersEntry$json = {
  '1': 'HeadersEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 11, '6': '.api.StringList', '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `GRPCResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List gRPCResponseDescriptor = $convert.base64Decode(
    'CgxHUlBDUmVzcG9uc2USOAoHaGVhZGVycxgBIAMoCzIeLmFwaS5HUlBDUmVzcG9uc2UuSGVhZG'
    'Vyc0VudHJ5UgdoZWFkZXJzEhgKB3BheWxvYWQYAiABKAxSB3BheWxvYWQaSwoMSGVhZGVyc0Vu'
    'dHJ5EhAKA2tleRgBIAEoCVIDa2V5EiUKBXZhbHVlGAIgASgLMg8uYXBpLlN0cmluZ0xpc3RSBX'
    'ZhbHVlOgI4AQ==');

@$core.Deprecated('Use sQLQueryDescriptor instead')
const SQLQuery$json = {
  '1': 'SQLQuery',
  '2': [
    {'1': 'query', '3': 1, '4': 1, '5': 9, '10': 'query'},
    {'1': 'params', '3': 2, '4': 1, '5': 11, '6': '.api.StringList', '10': 'params'},
  ],
};

/// Descriptor for `SQLQuery`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sQLQueryDescriptor = $convert.base64Decode(
    'CghTUUxRdWVyeRIUCgVxdWVyeRgBIAEoCVIFcXVlcnkSJwoGcGFyYW1zGAIgASgLMg8uYXBpLl'
    'N0cmluZ0xpc3RSBnBhcmFtcw==');

@$core.Deprecated('Use sQLResponseDescriptor instead')
const SQLResponse$json = {
  '1': 'SQLResponse',
  '2': [
    {'1': 'columns', '3': 1, '4': 1, '5': 11, '6': '.api.StringList', '10': 'columns'},
    {'1': 'rows', '3': 2, '4': 3, '5': 11, '6': '.api.StringList', '10': 'rows'},
  ],
};

/// Descriptor for `SQLResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sQLResponseDescriptor = $convert.base64Decode(
    'CgtTUUxSZXNwb25zZRIpCgdjb2x1bW5zGAEgASgLMg8uYXBpLlN0cmluZ0xpc3RSB2NvbHVtbn'
    'MSIwoEcm93cxgCIAMoCzIPLmFwaS5TdHJpbmdMaXN0UgRyb3dz');

@$core.Deprecated('Use replyDescriptor instead')
const Reply$json = {
  '1': 'Reply',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `Reply`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List replyDescriptor = $convert.base64Decode(
    'CgVSZXBseRIWCgZzdGF0dXMYASABKAlSBnN0YXR1cw==');

@$core.Deprecated('Use agentStartedDescriptor instead')
const AgentStarted$json = {
  '1': 'AgentStarted',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `AgentStarted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentStartedDescriptor = $convert.base64Decode(
    'CgxBZ2VudFN0YXJ0ZWQSGAoHdmVyc2lvbhgBIAEoCVIHdmVyc2lvbg==');

@$core.Deprecated('Use agentVerifiedDescriptor instead')
const AgentVerified$json = {
  '1': 'AgentVerified',
  '2': [
    {'1': 'valid', '3': 1, '4': 1, '5': 8, '10': 'valid'},
    {'1': 'message', '3': 2, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `AgentVerified`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List agentVerifiedDescriptor = $convert.base64Decode(
    'Cg1BZ2VudFZlcmlmaWVkEhQKBXZhbGlkGAEgASgIUgV2YWxpZBIYCgdtZXNzYWdlGAIgASgJUg'
    'dtZXNzYWdl');

@$core.Deprecated('Use commandDescriptor instead')
const Command$json = {
  '1': 'Command',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 9, '10': 'type'},
    {'1': 'settings', '3': 2, '4': 1, '5': 11, '6': '.api.Settings', '10': 'settings'},
  ],
};

/// Descriptor for `Command`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List commandDescriptor = $convert.base64Decode(
    'CgdDb21tYW5kEhIKBHR5cGUYASABKAlSBHR5cGUSKQoIc2V0dGluZ3MYAiABKAsyDS5hcGkuU2'
    'V0dGluZ3NSCHNldHRpbmdz');

@$core.Deprecated('Use settingsDescriptor instead')
const Settings$json = {
  '1': 'Settings',
  '2': [
    {'1': 'container_ids', '3': 1, '4': 3, '5': 9, '10': 'containerIds'},
    {'1': 'license_key', '3': 2, '4': 1, '5': 9, '10': 'licenseKey'},
  ],
};

/// Descriptor for `Settings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List settingsDescriptor = $convert.base64Decode(
    'CghTZXR0aW5ncxIjCg1jb250YWluZXJfaWRzGAEgAygJUgxjb250YWluZXJJZHMSHwoLbGljZW'
    '5zZV9rZXkYAiABKAlSCmxpY2Vuc2VLZXk=');

@$core.Deprecated('Use requestDescriptor instead')
const Request$json = {
  '1': 'Request',
  '2': [
    {'1': 'num', '3': 1, '4': 1, '5': 5, '10': 'num'},
  ],
};

/// Descriptor for `Request`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List requestDescriptor = $convert.base64Decode(
    'CgdSZXF1ZXN0EhAKA251bRgBIAEoBVIDbnVt');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'result', '3': 1, '4': 1, '5': 5, '10': 'result'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRIWCgZyZXN1bHQYASABKAVSBnJlc3VsdA==');

@$core.Deprecated('Use containerDescriptor instead')
const Container$json = {
  '1': 'Container',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'image', '3': 2, '4': 1, '5': 9, '10': 'image'},
    {'1': 'ip', '3': 3, '4': 1, '5': 9, '10': 'ip'},
    {'1': 'name', '3': 4, '4': 1, '5': 9, '10': 'name'},
    {'1': 'status', '3': 5, '4': 1, '5': 9, '10': 'status'},
  ],
};

/// Descriptor for `Container`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List containerDescriptor = $convert.base64Decode(
    'CglDb250YWluZXISDgoCaWQYASABKAlSAmlkEhQKBWltYWdlGAIgASgJUgVpbWFnZRIOCgJpcB'
    'gDIAEoCVICaXASEgoEbmFtZRgEIAEoCVIEbmFtZRIWCgZzdGF0dXMYBSABKAlSBnN0YXR1cw==');

@$core.Deprecated('Use containersDescriptor instead')
const Containers$json = {
  '1': 'Containers',
  '2': [
    {'1': 'containers', '3': 1, '4': 3, '5': 11, '6': '.api.Container', '10': 'containers'},
  ],
};

/// Descriptor for `Containers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List containersDescriptor = $convert.base64Decode(
    'CgpDb250YWluZXJzEi4KCmNvbnRhaW5lcnMYASADKAsyDi5hcGkuQ29udGFpbmVyUgpjb250YW'
    'luZXJz');

