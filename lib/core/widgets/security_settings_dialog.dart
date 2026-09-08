import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../security/security_controller.dart';

/// Dialog allowing users to configure Biometric lock, PIN protection, and trigger immediate locking.
class SecuritySettingsDialog extends ConsumerStatefulWidget {
  const SecuritySettingsDialog({super.key});

  @override
  ConsumerState<SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends ConsumerState<SecuritySettingsDialog> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _showSetPinDialog() {
    _pinController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Configure Security PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter a 4 to 8 digit PIN for application unlock fallback:'),
              const SizedBox(height: 16),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'New PIN',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = _pinController.text.trim();
                if (pin.length >= 4) {
                  await ref.read(securityControllerProvider.notifier).setPin(pin);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN configured successfully.')),
                    );
                  }
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final secState = ref.watch(securityControllerProvider);
    final secNotifier = ref.read(securityControllerProvider.notifier);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, color: Colors.blueAccent),
          SizedBox(width: 8),
          Text('Security & Privacy'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Privacy Lock'),
              subtitle: const Text('Require authentication when app returns from background or restarts.'),
              value: secState.isLockEnabled,
              onChanged: (val) {
                secNotifier.setLockEnabled(val);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric Authentication'),
              subtitle: Text(
                secState.biometricAvailable
                    ? 'Supported (Fingerprint / Face ID / Hello)'
                    : 'Not available on this device',
              ),
              trailing: Icon(
                secState.biometricAvailable ? Icons.check_circle : Icons.error_outline,
                color: secState.biometricAvailable ? Colors.green : Colors.grey,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('PIN Fallback'),
              subtitle: Text(secState.hasPin ? 'PIN is configured' : 'No PIN set'),
              trailing: secState.hasPin
                  ? TextButton(
                      onPressed: () async {
                        await secNotifier.removePin();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN removed.')),
                          );
                        }
                      },
                      child: const Text('Remove'),
                    )
                  : ElevatedButton(
                      onPressed: _showSetPinDialog,
                      child: const Text('Set PIN'),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (secState.isLockEnabled)
          OutlinedButton.icon(
            icon: const Icon(Icons.lock),
            label: const Text('Lock Now'),
            onPressed: () {
              Navigator.of(context).pop();
              secNotifier.lock();
            },
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
