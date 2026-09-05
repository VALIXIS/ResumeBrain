import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'pin_service.dart';

/// Immutable state for application security, privacy locking, biometrics, and PIN settings.
class SecurityState {
  final bool isLockEnabled;
  final bool isLocked;
  final bool biometricAvailable;
  final bool hasPin;
  final bool isLockedOut;
  final String? errorMessage;

  const SecurityState({
    this.isLockEnabled = false,
    this.isLocked = false,
    this.biometricAvailable = false,
    this.hasPin = false,
    this.isLockedOut = false,
    this.errorMessage,
  });

  SecurityState copyWith({
    bool? isLockEnabled,
    bool? isLocked,
    bool? biometricAvailable,
    bool? hasPin,
    bool? isLockedOut,
    String? errorMessage,
  }) {
    return SecurityState(
      isLockEnabled: isLockEnabled ?? this.isLockEnabled,
      isLocked: isLocked ?? this.isLocked,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      hasPin: hasPin ?? this.hasPin,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      errorMessage: errorMessage,
    );
  }
}

/// Riverpod StateNotifier controlling privacy lock enforcement, biometric auth, and PIN verification.
class SecurityController extends StateNotifier<SecurityState> with WidgetsBindingObserver {
  static const String kLockEnabledKey = 'resume_brain_security_lock_enabled';

  final LocalAuthentication _localAuth;
  final PinService _pinService;
  final FlutterSecureStorage _secureStorage;

  SecurityController({
    LocalAuthentication? localAuth,
    PinService? pinService,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _pinService = pinService ?? PinService(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(const SecurityState()) {
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  PinService get pinService => _pinService;

  Future<void> init() async {
    bool bioAvailable = false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      bioAvailable = canCheck || isDeviceSupported;
    } catch (_) {
      bioAvailable = false;
    }

    bool lockEnabled = false;
    try {
      final storedVal = await _secureStorage.read(key: kLockEnabledKey);
      lockEnabled = storedVal == 'true';
    } catch (_) {
      lockEnabled = false;
    }

    final hasPin = await _pinService.hasPin();

    state = SecurityState(
      isLockEnabled: lockEnabled,
      isLocked: lockEnabled, // Always start locked if lock is enabled
      biometricAvailable: bioAvailable,
      hasPin: hasPin,
      isLockedOut: _pinService.isLockedOut,
    );
  }

  /// Sets whether privacy lock is enabled for the app.
  Future<void> setLockEnabled(bool enabled) async {
    try {
      await _secureStorage.write(key: kLockEnabledKey, value: enabled ? 'true' : 'false');
      state = state.copyWith(
        isLockEnabled: enabled,
        isLocked: enabled ? state.isLocked : false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update lock settings: $e');
    }
  }

  /// Manually locks the application.
  void lock() {
    if (state.isLockEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  /// Unlocks the application state after successful authentication.
  void unlock() {
    state = state.copyWith(isLocked: false, errorMessage: null);
  }

  /// Authenticates user using platform biometrics. Returns true on success.
  Future<bool> authenticateWithBiometrics() async {
    if (!state.biometricAvailable) {
      state = state.copyWith(errorMessage: 'Biometric authentication is unavailable on this device.');
      return false;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access protected resume data',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        unlock();
        return true;
      } else {
        state = state.copyWith(errorMessage: 'Biometric authentication failed or canceled.');
        return false;
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Biometric authentication error: $e');
      return false;
    }
  }

  /// Verifies PIN and unlocks application if correct.
  Future<bool> authenticateWithPin(String pin) async {
    final success = await _pinService.verifyPin(pin);
    if (success) {
      unlock();
      return true;
    } else {
      state = state.copyWith(
        isLockedOut: _pinService.isLockedOut,
        errorMessage: _pinService.isLockedOut
            ? 'Too many failed attempts. Temporarily locked out.'
            : 'Incorrect PIN. Please try again.',
      );
      return false;
    }
  }

  /// Sets a new PIN and enables lock if requested.
  Future<void> setPin(String pin) async {
    await _pinService.setPin(pin);
    final hasPin = await _pinService.hasPin();
    state = state.copyWith(hasPin: hasPin);
  }

  /// Removes PIN configuration.
  Future<void> removePin() async {
    await _pinService.removePin();
    state = state.copyWith(hasPin: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (this.state.isLockEnabled) {
        lock();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final securityControllerProvider =
    StateNotifierProvider<SecurityController, SecurityState>((ref) {
  return SecurityController();
});
