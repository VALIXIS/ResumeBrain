import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/core/storage/storage_bootstrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Onboarding Persistence Tests', () {
    test('StorageBootstrapService defaults isOnboardingCompleted to false', () {
      final storage = StorageBootstrapService();
      expect(storage.isOnboardingCompleted, isFalse);
    });
  });
}
