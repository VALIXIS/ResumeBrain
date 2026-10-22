import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/monetization/services/ad_service.dart';
import 'package:resume_brain/features/templates/models/resume_template.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RSM-10 AdUnitIds Configuration', () {
    test('Configures official Google AdMob test ad units for debug mode', () {
      final debugAdUnit = AdUnitIds.getRewardedAdUnitId(isDebug: true);
      expect(
        debugAdUnit,
        anyOf(
          equals(AdUnitIds.androidTestRewardedAdUnitId),
          equals(AdUnitIds.iosTestRewardedAdUnitId),
        ),
      );
      expect(debugAdUnit, contains('3940256099942544'));
    });

    test('Configures production ad units for release mode', () {
      final prodAdUnit = AdUnitIds.getRewardedAdUnitId(isDebug: false);
      expect(
        prodAdUnit,
        anyOf(
          equals(AdUnitIds.androidProductionRewardedAdUnitId),
          equals(AdUnitIds.iosProductionRewardedAdUnitId),
        ),
      );
      expect(prodAdUnit, isNot(contains('3940256099942544')));
    });
  });

  group('RSM-10 RewardedAd Listener Architecture', () {
    test('RewardedAd.load dispatches onAdLoaded callback with loaded instance', () async {
      bool loadedCalled = false;
      RewardedAd? loadedAd;

      await RewardedAd.load(
        adUnitId: AdUnitIds.androidTestRewardedAdUnitId,
        latency: Duration.zero,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            loadedCalled = true;
            loadedAd = ad;
          },
          onAdFailedToLoad: (error) {
            fail('Ad load should not fail');
          },
        ),
      );

      expect(loadedCalled, isTrue);
      expect(loadedAd, isNotNull);
      expect(loadedAd!.isLoaded, isTrue);
      expect(loadedAd!.adUnitId, equals(AdUnitIds.androidTestRewardedAdUnitId));
    });

    test('Configures FullScreenContentCallback listeners properly', () {
      final ad = RewardedAd(adUnitId: AdUnitIds.androidTestRewardedAdUnitId);
      bool showed = false;
      bool dismissed = false;
      bool clicked = false;
      bool impression = false;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) => showed = true,
        onAdDismissedFullScreenContent: (ad) => dismissed = true,
        onAdClicked: (ad) => clicked = true,
        onAdImpression: (ad) => impression = true,
      );

      ad.fullScreenContentCallback?.onAdShowedFullScreenContent?.call(ad);
      ad.fullScreenContentCallback?.onAdImpression?.call(ad);
      ad.fullScreenContentCallback?.onAdClicked?.call(ad);
      ad.fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(ad);

      expect(showed, isTrue);
      expect(impression, isTrue);
      expect(clicked, isTrue);
      expect(dismissed, isTrue);
    });
  });

  group('RSM-10 SessionUnlockedTemplatesNotifier', () {
    late SessionUnlockedTemplatesNotifier notifier;

    setUp(() {
      notifier = SessionUnlockedTemplatesNotifier();
    });

    test('Correctly identifies Executive templates vs free ATS templates', () {
      expect(SessionUnlockedTemplatesNotifier.isExecutiveTemplate('executive_minimal'), isTrue);
      expect(SessionUnlockedTemplatesNotifier.isExecutiveTemplate('executive_modern'), isTrue);
      expect(SessionUnlockedTemplatesNotifier.isExecutiveTemplate('modern_classic'), isFalse);
      expect(SessionUnlockedTemplatesNotifier.isExecutiveTemplate('tech_modern'), isFalse);
      expect(SessionUnlockedTemplatesNotifier.isExecutiveTemplate('academic_clean'), isFalse);
    });

    test('Executive templates start locked; free templates start unlocked', () {
      expect(notifier.isTemplateUnlocked('modern_classic'), isTrue);
      expect(notifier.isTemplateUnlocked('tech_modern'), isTrue);
      expect(notifier.isTemplateUnlocked('executive_minimal'), isFalse);
    });

    test('Unlocking Executive template permanently unlocks for that session', () {
      expect(notifier.isTemplateUnlocked('executive_minimal'), isFalse);

      notifier.unlockTemplate('executive_minimal');

      expect(notifier.isTemplateUnlocked('executive_minimal'), isTrue);
      expect(notifier.state, contains('executive_minimal'));
    });

    test('Session reset re-locks Executive templates', () {
      notifier.unlockTemplate('executive_minimal');
      expect(notifier.isTemplateUnlocked('executive_minimal'), isTrue);

      notifier.resetSession();

      expect(notifier.isTemplateUnlocked('executive_minimal'), isFalse);
      expect(notifier.state.isEmpty, isTrue);
    });
  });

  group('RSM-10 AiInterviewTokensNotifier Token Gating & Rewards', () {
    late AiInterviewTokensNotifier tokensNotifier;

    setUp(() {
      tokensNotifier = AiInterviewTokensNotifier();
      tokensNotifier.setTokensForTesting(2);
    });

    test('Starts with welcome tokens balance', () {
      expect(tokensNotifier.state, equals(2));
    });

    test('Grants 1 free AI Interview session token per rewarded ad view', () async {
      final initialTokens = tokensNotifier.state;
      await tokensNotifier.grantToken(1);

      expect(tokensNotifier.state, equals(initialTokens + 1));

      await tokensNotifier.grantToken(1);
      expect(tokensNotifier.state, equals(initialTokens + 2));
    });

    test('useToken decrements token count when available', () async {
      tokensNotifier.setTokensForTesting(1);

      final result1 = await tokensNotifier.useToken();
      expect(result1, isTrue);
      expect(tokensNotifier.state, equals(0));

      final result2 = await tokensNotifier.useToken();
      expect(result2, isFalse);
      expect(tokensNotifier.state, equals(0));
    });
  });

  group('RSM-10 TemplateRegistry and ResumeTemplate Extensions', () {
    test('ExecutiveMinimalTemplate has isExecutive == true', () {
      final executiveTemplate = TemplateRegistry.getTemplateById('executive_minimal');
      expect(executiveTemplate.isExecutive, isTrue);
      expect(executiveTemplate.name, equals('Executive Minimal'));
    });

    test('Other ATS templates have isExecutive == false', () {
      final modernClassic = TemplateRegistry.getTemplateById('modern_classic');
      final techModern = TemplateRegistry.getTemplateById('tech_modern');
      final academicClean = TemplateRegistry.getTemplateById('academic_clean');

      expect(modernClassic.isExecutive, isFalse);
      expect(techModern.isExecutive, isFalse);
      expect(academicClean.isExecutive, isFalse);
    });
  });
}
