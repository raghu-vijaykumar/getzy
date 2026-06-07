import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../settings/settings_repository.dart';

enum ConstraintViolation {
  wifiOnly,
  vpnOnly,
  chargingOnly,
  batteryLimit,
  storagePermission,
}

extension ConstraintViolationLabel on ConstraintViolation {
  String get message {
    switch (this) {
      case ConstraintViolation.wifiOnly:
        return 'WiFi only — no WiFi connection';
      case ConstraintViolation.vpnOnly:
        return 'VPN only — no VPN connection';
      case ConstraintViolation.chargingOnly:
        return 'Charging only — device not charging';
      case ConstraintViolation.batteryLimit:
        return 'Battery too low';
      case ConstraintViolation.storagePermission:
        return 'Storage permission needed';
    }
  }
}

class ConstraintChecker {
  ConstraintChecker() : _settings = SettingsRepository.instance;

  final SettingsRepository _settings;
  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  final StreamController<List<ConstraintViolation>> _violationsController =
      StreamController<List<ConstraintViolation>>.broadcast();

  Stream<List<ConstraintViolation>> get violations =>
      _violationsController.stream;
  List<ConstraintViolation> _currentViolations = [];
  List<ConstraintViolation> get currentViolations => _currentViolations;

  StreamSubscription? _connectivitySub;
  StreamSubscription? _batterySub;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _connectivitySub =
        _connectivity.onConnectivityChanged.listen((_) => _checkConstraints());

    _batterySub =
        _battery.onBatteryStateChanged.listen((_) => _checkConstraints());

    await _checkConstraints();
  }

  Future<void> _checkConstraints() async {
    final violations = <ConstraintViolation>[];

    try {
      final wifiOnlyRaw = await _settings.loadValue('wifi_only');
      if (wifiOnlyRaw == 'true') {
        final result = await _connectivity.checkConnectivity();
        final onWifi = result == ConnectivityResult.wifi || result == ConnectivityResult.ethernet;
        if (!onWifi) {
          violations.add(ConstraintViolation.wifiOnly);
        }
      }

      final vpnOnlyRaw = await _settings.loadValue('vpn_only');
      if (vpnOnlyRaw == 'true') {
        final result = await _connectivity.checkConnectivity();
        final onVpn = result == ConnectivityResult.vpn;
        if (!onVpn) {
          violations.add(ConstraintViolation.vpnOnly);
        }
      }

      final chargingOnlyRaw = await _settings.loadValue('charging_only');
      if (chargingOnlyRaw == 'true') {
        final state = await _battery.batteryState;
        final isCharging = state == BatteryState.charging || state == BatteryState.full;
        if (!isCharging) {
          violations.add(ConstraintViolation.chargingOnly);
        }
      }

      final batteryLimitRaw = await _settings.loadValue('battery_limit');
      if (batteryLimitRaw == 'true') {
        final levelRaw = await _settings.loadValue('battery_level');
        final limit = int.tryParse(levelRaw ?? '') ?? 25;
        final level = await _battery.batteryLevel;
        if (level < limit) {
          violations.add(ConstraintViolation.batteryLimit);
        }
      }
    } catch (_) {
      // Plugins may not be available in all environments (test, desktop, web).
      // When unavailable, constraints cannot be evaluated — assume no violations.
    }

    _currentViolations = violations;
    _violationsController.add(violations);
  }

  Future<void> triggerCheck() => _checkConstraints();

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    await _batterySub?.cancel();
    await _violationsController.close();
  }
}
