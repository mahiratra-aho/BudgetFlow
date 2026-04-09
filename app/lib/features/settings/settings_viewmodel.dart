import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/security/security_service.dart';

class SettingsState {
  final bool securityEnabled;
  final bool pinSet;
  final bool biometricAvailable;
  final String appVersion;

  const SettingsState({
    this.securityEnabled = false,
    this.pinSet = false,
    this.biometricAvailable = false,
    this.appVersion = '1.0.0',
  });

  SettingsState copyWith({
    bool? securityEnabled,
    bool? pinSet,
    bool? biometricAvailable,
  }) {
    return SettingsState(
      securityEnabled: securityEnabled ?? this.securityEnabled,
      pinSet: pinSet ?? this.pinSet,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      appVersion: appVersion,
    );
  }
}

class SettingsViewModel extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    return _loadSettings();
  }

  Future<SettingsState> _loadSettings() async {
    final results = await Future.wait([
      SecurityService.instance.isSecurityEnabled(),
      SecurityService.instance.isPinSet(),
      SecurityService.instance.isBiometricAvailable(),
    ]);
    return SettingsState(
      securityEnabled: results[0],
      pinSet: results[1],
      biometricAvailable: results[2],
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadSettings);
  }

  Future<void> setSecurityEnabled(bool enabled) async {
    await SecurityService.instance.setSecurityEnabled(enabled);
    await refresh();
  }

  Future<void> clearPin() async {
    await SecurityService.instance.clearPin();
    await refresh();
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', false);
  }
}

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsState>(
  SettingsViewModel.new,
);
