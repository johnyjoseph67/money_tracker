import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Fingerprint / face check using the phone's own biometrics.
class BiometricService {
  final _auth = LocalAuthentication();

  /// True when the phone has biometrics set up and ready to use.
  Future<bool> available() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system prompt. Returns null on success, otherwise a message explaining what went wrong.
  Future<String?> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Sign in to My Book',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      return ok ? null : 'Fingerprint or face not recognised, or the check was cancelled.';
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'no_fragment_activity':
          return 'Setup problem: change MainActivity to extend FlutterFragmentActivity, then rebuild the app.';
        case 'NotAvailable':
        case 'notAvailable':
          return 'Biometrics are not available on this phone, or the app theme is not supported (see setup step).';
        case 'NotEnrolled':
        case 'notEnrolled':
        case 'PasscodeNotSet':
        case 'passcodeNotSet':
          return 'No fingerprint or face is set up. Add one in the phone settings, then try again.';
        case 'LockedOut':
        case 'lockedOut':
          return 'Too many attempts. Wait 30 seconds and try again.';
        case 'PermanentlyLockedOut':
        case 'permanentlyLockedOut':
          return 'Biometrics are locked. Unlock the phone with your PIN or pattern first.';
        case 'auth_in_progress':
          return 'A biometric check is already open.';
        default:
          return 'Biometric error (${e.code}): ${e.message ?? 'unknown'}';
      }
    } catch (e) {
      return 'Biometric error: $e';
    }
  }
}