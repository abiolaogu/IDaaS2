import 'package:otp/otp.dart';

class TotpService {
  /// Generate a TOTP code for the given secret
  ///
  /// [secret] - Base32 encoded secret key
  /// [time] - Current time (defaults to now)
  /// [digits] - Number of digits in the code (default: 6)
  /// [period] - Time period in seconds (default: 30)
  static String generateCode({
    required String secret,
    DateTime? time,
    int digits = 6,
    int period = 30,
  }) {
    final currentTime = time ?? DateTime.now();
    final code = OTP.generateTOTPCodeString(
      secret,
      currentTime.millisecondsSinceEpoch,
      length: digits,
      interval: period,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    return code;
  }

  /// Calculate remaining seconds until the current code expires
  ///
  /// [period] - Time period in seconds (default: 30)
  static int getRemainingSeconds({int period = 30}) {
    final now = DateTime.now();
    final secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    final remainingSeconds = period - (secondsSinceEpoch % period);
    return remainingSeconds;
  }

  /// Calculate progress (0.0 to 1.0) for the current time period
  ///
  /// [period] - Time period in seconds (default: 30)
  static double getProgress({int period = 30}) {
    final remainingSeconds = getRemainingSeconds(period: period);
    return remainingSeconds / period;
  }

  /// Validate a TOTP code against a secret
  ///
  /// [code] - The code to validate
  /// [secret] - Base32 encoded secret key
  /// [time] - Current time (defaults to now)
  /// [digits] - Number of digits in the code (default: 6)
  /// [period] - Time period in seconds (default: 30)
  /// [window] - Number of time windows to check (default: 1, allows ±1 window)
  static bool validateCode({
    required String code,
    required String secret,
    DateTime? time,
    int digits = 6,
    int period = 30,
    int window = 1,
  }) {
    final currentTime = time ?? DateTime.now();
    final currentTimestamp = currentTime.millisecondsSinceEpoch;

    // Check current time window and adjacent windows
    for (int i = -window; i <= window; i++) {
      final adjustedTime = currentTimestamp + (i * period * 1000);
      final expectedCode = OTP.generateTOTPCodeString(
        secret,
        adjustedTime,
        length: digits,
        interval: period,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );

      if (code == expectedCode) {
        return true;
      }
    }

    return false;
  }

  /// Clean and validate a secret key
  /// Removes spaces and converts to uppercase
  static String? cleanSecret(String secret) {
    // Remove spaces and convert to uppercase
    final cleaned = secret.replaceAll(' ', '').toUpperCase();

    // Validate Base32 format (A-Z and 2-7)
    final base32Regex = RegExp(r'^[A-Z2-7]+=*$');
    if (!base32Regex.hasMatch(cleaned)) {
      return null;
    }

    return cleaned;
  }
}
