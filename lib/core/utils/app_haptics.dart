import 'package:flutter/services.dart';

/// Provides reliable tactile feedback across devices and Android OEMs.
///
/// Many Android devices silence standard [HapticFeedback] when the device
/// is set to silent or when OEM system touch haptics are toggled off.
/// [AppHaptics] invokes the native Android Vibrator service directly
/// with a graceful fallback to Flutter's [HapticFeedback].
class AppHaptics {
  static const MethodChannel _channel =
      MethodChannel('com.valixis.resumebrain/haptics');

  /// Triggered when the user grabs an item or starts dragging.
  static Future<void> dragGrab() async {
    try {
      await _channel.invokeMethod('vibrate', {'duration': 45});
    } catch (_) {}
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Triggered when an item is dropped into a new position.
  static Future<void> dragDrop() async {
    try {
      await _channel.invokeMethod('vibrate', {'duration': 65});
    } catch (_) {}
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
