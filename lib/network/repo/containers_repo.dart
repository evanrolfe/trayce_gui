import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trayce/agent/gen/api.pb.dart';
import 'package:trayce/agent/server.dart';

class EventDisplayContainers {
  static const minVersion = '1.0.0';

  final String? agentVersion;
  final List<Container> containers;
  final List<String> interceptedContainerIDs;

  EventDisplayContainers(this.agentVersion, this.containers, this.interceptedContainerIDs);

  int getExtendedVersionNumber(String version) {
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 100000 + versionCells[1] * 1000 + versionCells[2];
  }

  bool versionOk() {
    if (agentVersion == null) return false;

    try {
      final currentVersion = getExtendedVersionNumber(agentVersion!);
      final minimum = getExtendedVersionNumber(minVersion);
      return currentVersion >= minimum;
    } catch (e) {
      return false;
    }
  }
}

class EventAgentRunning {
  final bool running;

  EventAgentRunning(this.running);
}

class EventSendCommand {
  final Command command;

  EventSendCommand(this.command);
}

class ContainersRepo {
  final EventBus _eventBus;
  String? _agentVersion = '';
  bool _agentRunning = false;
  bool _isVerified = false;
  DateTime? _lastHeartbeatAt;
  final Settings _settings = Settings();
  EventDisplayContainers? _lastDisplayEvent;

  static const _licenseKeyPref = 'license_key';

  // Getters
  String? get licenseKey => _settings.licenseKey;
  bool get isVerified => _isVerified;
  bool get agentRunning => _agentRunning;
  EventDisplayContainers? get lastDisplayEvent => _lastDisplayEvent;

  ContainersRepo({
    required EventBus eventBus,
  }) : _eventBus = eventBus {
    _eventBus.on<EventAgentStarted>().listen((event) {
      _agentVersion = event.version;
    });

    _eventBus.on<EventAgentVerified>().listen((event) {
      _isVerified = event.valid;
    });

    _eventBus.on<EventContainersObserved>().listen((event) {
      _lastHeartbeatAt = DateTime.now();

      if (!_agentRunning) {
        _agentRunning = true;
        _sendSettings();
        _eventBus.fire(EventAgentRunning(true));
      }

      final displayEvent = EventDisplayContainers(_agentVersion, event.containers, _settings.containerIds);
      _lastDisplayEvent = displayEvent;
      _eventBus.fire(displayEvent);
    });

    // Start heartbeat check timer
    Timer.periodic(const Duration(milliseconds: 100), (_) => _checkHeartbeat());

    _initSettings();
  }

  Future<void> _initSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLicenseKey = prefs.getString(_licenseKeyPref);
    if (savedLicenseKey != null) {
      _settings.licenseKey = savedLicenseKey;
      _sendSettings();
    }
  }

  Future<void> setLicenseKey(String licenseKey) async {
    print('Setting license key: $licenseKey');
    _settings.licenseKey = licenseKey;

    // Save to persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_licenseKeyPref, licenseKey);

    _sendSettings();
  }

  void _checkHeartbeat() {
    if (_lastHeartbeatAt != null &&
        _agentRunning &&
        DateTime.now().difference(_lastHeartbeatAt!) > const Duration(seconds: 2)) {
      _agentRunning = false;
      print('REPO:Agent heartbeat check NOT RUNNING');
      _eventBus.fire(EventAgentRunning(false));
    }
  }

  // TODO: This could be improved because when you check a container in the modal, then close the modal
  // it remains checked the next time you open it even though you never pressed save
  void interceptContainers(List<String> containerIds) {
    print('Intercepting containers: $containerIds');
    _settings.containerIds.clear();
    _settings.containerIds.addAll(containerIds);
  }

  void save() {
    _sendSettings();
  }

  void _sendSettings() {
    final command = Command(type: 'set_settings', settings: _settings);
    _eventBus.fire(EventSendCommand(command));
  }
}
