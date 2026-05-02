import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../settings/app_settings.dart';
import '../settings/app_settings_controller.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.controller, required this.child});

  final AppSettingsController controller;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final settings = widget.controller.settings;
        if (!settings.appLockEnabled ||
            !settings.appLockConfigured ||
            _unlocked) {
          return widget.child;
        }

        return PinUnlockScreen(
          controller: widget.controller,
          onUnlocked: () => setState(() => _unlocked = true),
        );
      },
    );
  }
}

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({
    super.key,
    required this.controller,
    required this.onUnlocked,
  });

  final AppSettingsController controller;
  final VoidCallback onUnlocked;

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final TextEditingController _pinController = TextEditingController();
  String _error = '';
  bool _biometricAvailable = false;
  bool _checkingBiometrics = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _LockText(widget.controller.settings.language);
    final showBiometric =
        widget.controller.settings.biometricUnlockEnabled &&
        _biometricAvailable;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(28),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 42,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    text.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pinController,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    onSubmitted: (_) => _unlock(text),
                    decoration: InputDecoration(
                      labelText: text.pin,
                      errorText: _error.isEmpty ? null : _error,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _unlock(text),
                      icon: const Icon(Icons.lock_open_rounded),
                      label: Text(text.unlock),
                    ),
                  ),
                  if (showBiometric) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _authenticateBiometric,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(text.unlockWithBiometrics),
                      ),
                    ),
                  ] else if (widget
                          .controller
                          .settings
                          .biometricUnlockEnabled &&
                      !_checkingBiometrics) ...[
                    const SizedBox(height: 10),
                    Text(
                      text.biometricsUnavailable,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadBiometricState() async {
    try {
      final supported = await _localAuthentication.isDeviceSupported();
      final canCheck = await _localAuthentication.canCheckBiometrics;
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricAvailable = supported && canCheck;
        _checkingBiometrics = false;
      });
    } on PlatformException {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricAvailable = false;
        _checkingBiometrics = false;
      });
    }
  }

  Future<void> _authenticateBiometric() async {
    final text = _LockText(widget.controller.settings.language);
    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: text.biometricReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (authenticated) {
        widget.onUnlocked();
      }
    } on PlatformException {
      if (!mounted) {
        return;
      }
      setState(() => _error = text.biometricsFailed);
    }
  }

  void _unlock(_LockText text) {
    final pin = _pinController.text;
    if (widget.controller.verifyPin(pin)) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _error = text.error;
      _pinController.clear();
    });
  }
}

class _LockText {
  const _LockText(this.language);

  final AppLanguage language;

  bool get isRu => language == AppLanguage.ru;

  String get title => isRu ? 'MEMRYTH заблокирован' : 'MEMRYTH is locked';
  String get body => isRu
      ? 'Введите PIN, чтобы открыть вашу библиотеку.'
      : 'Enter your PIN to open your library.';
  String get pin => isRu ? 'PIN' : 'PIN';
  String get unlock => isRu ? 'Разблокировать' : 'Unlock';
  String get error => isRu ? 'Неверный PIN' : 'Incorrect PIN';
  String get unlockWithBiometrics =>
      isRu ? 'Разблокировать биометрией' : 'Unlock with biometrics';
  String get biometricReason => isRu
      ? 'Подтвердите личность, чтобы открыть MEMRYTH'
      : 'Authenticate to open MEMRYTH';
  String get biometricsUnavailable => isRu
      ? 'Биометрия недоступна на этом устройстве.'
      : 'Biometrics are unavailable on this device.';
  String get biometricsFailed => isRu
      ? 'Биометрическая проверка не выполнена.'
      : 'Biometric authentication failed.';
}
