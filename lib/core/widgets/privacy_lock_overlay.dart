import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/security_controller.dart';

/// Fullscreen overlay rendered when privacy lock is active, requiring Biometric or PIN authentication.
class PrivacyLockOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const PrivacyLockOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<PrivacyLockOverlay> createState() => _PrivacyLockOverlayState();
}

class _PrivacyLockOverlayState extends ConsumerState<PrivacyLockOverlay> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final secState = ref.watch(securityControllerProvider);
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.pin, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Enter Security PIN'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter your 4-digit PIN to access Resume Brain:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'PIN',
                    ),
                  ),
                  if (secState.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      secState.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: secState.isLockedOut
                      ? null
                      : () async {
                          final pin = _pinController.text;
                          final success = await ref
                              .read(securityControllerProvider.notifier)
                              .authenticateWithPin(pin);
                          if (success && context.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final secState = ref.watch(securityControllerProvider);

    if (!secState.isLocked) {
      return widget.child;
    }

    return Stack(
      children: [
        // Blurring background child
        widget.child,

        // High priority modal cover
        Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.92),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 72,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Resume Brain Locked',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Privacy lock is active to protect your personal resume data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (secState.biometricAvailable) ...[
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.fingerprint, color: Colors.white),
                        label: const Text(
                          'Unlock with Biometrics',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        onPressed: () {
                          ref
                              .read(securityControllerProvider.notifier)
                              .authenticateWithBiometrics();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (secState.hasPin)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.pin, color: Colors.white),
                        label: const Text(
                          'Unlock with PIN',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        onPressed: _showPinDialog,
                      ),
                    if (secState.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        secState.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
