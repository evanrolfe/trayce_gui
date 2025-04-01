//
//  Generated code. Do not modify.
//  source: api.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'api.pb.dart' as $0;

export 'api.pb.dart';

@$pb.GrpcServiceName('api.TrayceAgent')
class TrayceAgentClient extends $grpc.Client {
  static final _$sendFlowsObserved = $grpc.ClientMethod<$0.Flows, $0.Reply>(
      '/api.TrayceAgent/SendFlowsObserved',
      ($0.Flows value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Reply.fromBuffer(value));
  static final _$sendContainersObserved = $grpc.ClientMethod<$0.Containers, $0.Reply>(
      '/api.TrayceAgent/SendContainersObserved',
      ($0.Containers value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Reply.fromBuffer(value));
  static final _$sendAgentVerified = $grpc.ClientMethod<$0.AgentVerified, $0.Reply>(
      '/api.TrayceAgent/SendAgentVerified',
      ($0.AgentVerified value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Reply.fromBuffer(value));
  static final _$openCommandStream = $grpc.ClientMethod<$0.AgentStarted, $0.Command>(
      '/api.TrayceAgent/OpenCommandStream',
      ($0.AgentStarted value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.Command.fromBuffer(value));

  TrayceAgentClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.Reply> sendFlowsObserved($0.Flows request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sendFlowsObserved, request, options: options);
  }

  $grpc.ResponseFuture<$0.Reply> sendContainersObserved($0.Containers request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sendContainersObserved, request, options: options);
  }

  $grpc.ResponseFuture<$0.Reply> sendAgentVerified($0.AgentVerified request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$sendAgentVerified, request, options: options);
  }

  $grpc.ResponseStream<$0.Command> openCommandStream($async.Stream<$0.AgentStarted> request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$openCommandStream, request, options: options);
  }
}

@$pb.GrpcServiceName('api.TrayceAgent')
abstract class TrayceAgentServiceBase extends $grpc.Service {
  $core.String get $name => 'api.TrayceAgent';

  TrayceAgentServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.Flows, $0.Reply>(
        'SendFlowsObserved',
        sendFlowsObserved_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Flows.fromBuffer(value),
        ($0.Reply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Containers, $0.Reply>(
        'SendContainersObserved',
        sendContainersObserved_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Containers.fromBuffer(value),
        ($0.Reply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AgentVerified, $0.Reply>(
        'SendAgentVerified',
        sendAgentVerified_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AgentVerified.fromBuffer(value),
        ($0.Reply value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AgentStarted, $0.Command>(
        'OpenCommandStream',
        openCommandStream,
        true,
        true,
        ($core.List<$core.int> value) => $0.AgentStarted.fromBuffer(value),
        ($0.Command value) => value.writeToBuffer()));
  }

  $async.Future<$0.Reply> sendFlowsObserved_Pre($grpc.ServiceCall call, $async.Future<$0.Flows> request) async {
    return sendFlowsObserved(call, await request);
  }

  $async.Future<$0.Reply> sendContainersObserved_Pre($grpc.ServiceCall call, $async.Future<$0.Containers> request) async {
    return sendContainersObserved(call, await request);
  }

  $async.Future<$0.Reply> sendAgentVerified_Pre($grpc.ServiceCall call, $async.Future<$0.AgentVerified> request) async {
    return sendAgentVerified(call, await request);
  }

  $async.Future<$0.Reply> sendFlowsObserved($grpc.ServiceCall call, $0.Flows request);
  $async.Future<$0.Reply> sendContainersObserved($grpc.ServiceCall call, $0.Containers request);
  $async.Future<$0.Reply> sendAgentVerified($grpc.ServiceCall call, $0.AgentVerified request);
  $async.Stream<$0.Command> openCommandStream($grpc.ServiceCall call, $async.Stream<$0.AgentStarted> request);
}
