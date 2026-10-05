import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/buttons.dart';
import '../../data/providers/data_providers.dart';

/// Face ID, fingerprint or device passcode. Tests replace these.
abstract interface class Authenticator {
  /// True when the phone has some screen lock the app can use.
  Future<bool> isAvailable();

  /// Shows the system prompt. True when the user passed it.
  Future<bool> authenticate(String reason);
}

class LocalAuthenticator implements Authenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      // Not biometric only: the device passcode also works.
      return await _auth.authenticate(localizedReason: reason);
    } on Object {
      return false;
    }
  }
}

final authenticatorProvider = Provider<Authenticator>(
  (ref) => LocalAuthenticator(),
);

/// Covers the app with a lock screen when App lock is on: at start and
/// whenever the app comes back from the background.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  late bool _locked = ref.read(currentSettingsProvider).appLock;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final enabled = ref.read(currentSettingsProvider).appLock;
    // "paused" means really in the background. The system prompt itself
    // only makes the app "inactive", so it does not lock again.
    if (state == AppLifecycleState.paused && enabled) {
      setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_asking) return;
    _asking = true;
    final ok = await ref
        .read(authenticatorProvider)
        .authenticate('Unlock Personal Finance');
    _asking = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    // Turning the setting off unlocks right away.
    final enabled = ref.watch(currentSettingsProvider).appLock;
    return Stack(
      children: [
        widget.child,
        if (_locked && enabled) _LockScreen(onUnlock: _unlock),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned.fill(
      child: Material(
        color: c.background,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: AppIcon(
                    AppIcons.lock,
                    size: 32,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Personal Finance is locked',
                  textAlign: TextAlign.center,
                  style: AppText.title20.copyWith(letterSpacing: 0),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use Face ID, your fingerprint or your passcode to open it.',
                  textAlign: TextAlign.center,
                  style: AppText.body15Regular.copyWith(color: c.textSecondary),
                ),
                const Spacer(),
                PrimaryButton(label: 'Unlock', onPressed: onUnlock),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
