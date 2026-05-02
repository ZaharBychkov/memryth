import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PinLockService {
  const PinLockService._();

  static const minPinLength = 4;
  static const maxPinLength = 8;

  static bool isValidPin(String value) {
    return RegExp(r'^\d{4,8}$').hasMatch(value);
  }

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  static bool verifyPin({
    required String pin,
    required String salt,
    required String hash,
  }) {
    if (!isValidPin(pin) || salt.isEmpty || hash.isEmpty) {
      return false;
    }
    return hashPin(pin, salt) == hash;
  }
}
