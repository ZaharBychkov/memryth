import 'package:flutter_test/flutter_test.dart';
import 'package:memryth_dart_project/services/pin_lock_service.dart';

void main() {
  group('PinLockService', () {
    test('accepts only 4 to 8 digit PINs', () {
      expect(PinLockService.isValidPin('1234'), isTrue);
      expect(PinLockService.isValidPin('12345678'), isTrue);
      expect(PinLockService.isValidPin('123'), isFalse);
      expect(PinLockService.isValidPin('123456789'), isFalse);
      expect(PinLockService.isValidPin('12a4'), isFalse);
      expect(PinLockService.isValidPin(''), isFalse);
    });

    test('hashes and verifies a PIN with salt', () {
      const pin = '4927';
      final salt = PinLockService.generateSalt();
      final hash = PinLockService.hashPin(pin, salt);

      expect(hash, isNot(pin));
      expect(
        PinLockService.verifyPin(pin: pin, salt: salt, hash: hash),
        isTrue,
      );
      expect(
        PinLockService.verifyPin(pin: '4928', salt: salt, hash: hash),
        isFalse,
      );
    });
  });
}
