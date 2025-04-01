import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:grpc/grpc.dart';
import 'package:trayce/network/repo/containers_repo.dart';

import 'command_sender.dart';
import 'gen/api.pbgrpc.dart';

class EventContainersObserved {
  final List<Container> containers;

  EventContainersObserved(this.containers);
}

class EventFlowsObserved {
  final List<Flow> flows;

  EventFlowsObserved(this.flows);
}

class EventAgentStarted {
  final String version;

  EventAgentStarted(this.version);
}

class EventAgentVerified {
  final bool valid;

  EventAgentVerified(this.valid);
}

class TrayceAgentService extends TrayceAgentServiceBase implements CommandSender {
  final _commandStreamControllers = <StreamController<Command>>[];
  final EventBus _eventBus;

  TrayceAgentService({required EventBus eventBus}) : _eventBus = eventBus {
    _eventBus.on<EventSendCommand>().listen((event) {
      sendCommandToAll(event.command);
    });
  }

  @override
  Future<Reply> sendFlowsObserved(ServiceCall call, Flows request) async {
    _eventBus.fire(EventFlowsObserved(request.flows));

    return Reply(status: 'success');
  }

  @override
  Future<Reply> sendContainersObserved(ServiceCall call, Containers request) async {
    _eventBus.fire(EventContainersObserved(request.containers));

    return Reply(status: 'success');
  }

  @override
  Future<Reply> sendAgentVerified(ServiceCall call, AgentVerified request) async {
    print('Agent verified: ${request.valid}');
    _eventBus.fire(EventAgentVerified(request.valid));

    return Reply(status: 'success');
  }

  @override
  Stream<Command> openCommandStream(ServiceCall call, Stream<AgentStarted> request) async* {
    await for (final agentStarted in request) {
      print('Agent started with version ${agentStarted.version}');
      _eventBus.fire(EventAgentStarted(agentStarted.version));

      final controller = StreamController<Command>();
      _commandStreamControllers.add(controller);

      try {
        await for (final command in controller.stream) {
          yield command;
        }
      } finally {
        _commandStreamControllers.remove(controller);
        await controller.close();
      }
    }
  }

  @override
  void sendCommandToAll(Command command) {
    for (var controller in _commandStreamControllers) {
      controller.add(command);
    }
  }
}
