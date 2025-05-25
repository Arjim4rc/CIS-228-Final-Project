import 'package:local_auth/local_auth.dart';

class BiometricHelper {
  static final _auth = LocalAuthentication();

  static Future<bool> hasBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      print('Can check biometrics: $canCheck');
      return canCheck;
    } catch (e) {
      print('Error checking biometrics: $e');
      return false;
    }
  }

  static Future<bool> authenticateWithBiometrics() async {
    try {
      final isAvailable = await hasBiometrics();
      if (!isAvailable) {
        print('Biometrics not available');
        return false;
      }

      final isSupported = await _auth.isDeviceSupported();
      print('Device supported biometrics: $isSupported');
      if (!isSupported) {
        return false;
      }

      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          // Use this option if you want to allow device passcode fallback
          // useErrorDialogs: true,
        ),
      );

      print('Authentication success: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }
}