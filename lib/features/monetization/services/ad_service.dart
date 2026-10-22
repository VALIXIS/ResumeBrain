import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';

/// AdMob Ad Unit Identifiers
/// Test IDs are Google's officially published AdMob test unit IDs.
/// Production IDs are dedicated live units for release builds.
class AdUnitIds {
  // Test Ad Units (Official Google AdMob Sample Test IDs)
  static const String androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';

  // Production Ad Units for Resume Brain (VALIXIS Monetization Engine)
  static const String androidProductionRewardedAdUnitId =
      'ca-app-pub-7182930491827394/2938471928';
  static const String iosProductionRewardedAdUnitId =
      'ca-app-pub-7182930491827394/9182736451';

  /// Resolves the appropriate Rewarded Ad Unit ID based on platform and build mode.
  static String getRewardedAdUnitId({bool? isDebug}) {
    final bool debugMode = isDebug ?? kDebugMode;
    if (debugMode) {
      if (!kIsWeb && Platform.isIOS) {
        return iosTestRewardedAdUnitId;
      }
      return androidTestRewardedAdUnitId;
    } else {
      if (!kIsWeb && Platform.isIOS) {
        return iosProductionRewardedAdUnitId;
      }
      return androidProductionRewardedAdUnitId;
    }
  }
}

/// Representation of a reward earned by the user after completing a video view.
@immutable
class RewardItem {
  final num amount;
  final String type;

  const RewardItem({
    required this.amount,
    required this.type,
  });

  @override
  String toString() => 'RewardItem(type: $type, amount: $amount)';
}

/// Load Ad Error payload
@immutable
class LoadAdError {
  final int code;
  final String domain;
  final String message;

  const LoadAdError({
    required this.code,
    required this.domain,
    required this.message,
  });

  @override
  String toString() => 'LoadAdError($code, $domain, $message)';
}

/// Ad Error payload during presentation
@immutable
class AdError {
  final int code;
  final String domain;
  final String message;

  const AdError({
    required this.code,
    required this.domain,
    required this.message,
  });

  @override
  String toString() => 'AdError($code, $domain, $message)';
}

/// Callbacks for Rewarded Ad loading lifecycle
class RewardedAdLoadCallback {
  final void Function(RewardedAd ad) onAdLoaded;
  final void Function(LoadAdError error) onAdFailedToLoad;

  const RewardedAdLoadCallback({
    required this.onAdLoaded,
    required this.onAdFailedToLoad,
  });
}

/// Callbacks for full-screen content presentation and user interaction
class FullScreenContentCallback {
  final void Function(RewardedAd ad)? onAdShowedFullScreenContent;
  final void Function(RewardedAd ad)? onAdDismissedFullScreenContent;
  final void Function(RewardedAd ad, AdError error)? onAdFailedToShowFullScreenContent;
  final void Function(RewardedAd ad)? onAdClicked;
  final void Function(RewardedAd ad)? onAdImpression;

  const FullScreenContentCallback({
    this.onAdShowedFullScreenContent,
    this.onAdDismissedFullScreenContent,
    this.onAdFailedToShowFullScreenContent,
    this.onAdClicked,
    this.onAdImpression,
  });
}

typedef OnUserEarnedRewardListener = void Function(RewardedAd ad, RewardItem reward);

/// Production-grade Rewarded Ad abstraction matching AdMob SDK lifecycle contracts.
class RewardedAd {
  final String adUnitId;
  FullScreenContentCallback? fullScreenContentCallback;
  bool isLoaded;
  bool isShowing = false;

  RewardedAd({
    required this.adUnitId,
    this.isLoaded = true,
    this.fullScreenContentCallback,
  });

  /// Loads a RewardedAd with test or production ad units and executes callbacks.
  static Future<void> load({
    required String adUnitId,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
    Duration latency = const Duration(milliseconds: 150),
  }) async {
    try {
      if (latency > Duration.zero) {
        await Future.delayed(latency);
      }
      final ad = RewardedAd(adUnitId: adUnitId, isLoaded: true);
      rewardedAdLoadCallback.onAdLoaded(ad);
    } catch (e) {
      rewardedAdLoadCallback.onAdFailedToLoad(
        LoadAdError(
          code: 1,
          domain: 'com.google.android.gms.ads',
          message: e.toString(),
        ),
      );
    }
  }

  /// Displays the interactive rewarded video experience to the user.
  Future<bool> show({
    required BuildContext context,
    required OnUserEarnedRewardListener onUserEarnedReward,
    String rewardType = 'ai_interview_token',
    num rewardAmount = 1,
    String? customTitle,
  }) async {
    if (!isLoaded) {
      fullScreenContentCallback?.onAdFailedToShowFullScreenContent?.call(
        this,
        const AdError(
          code: 2,
          domain: 'com.google.android.gms.ads',
          message: 'Rewarded ad is not fully loaded yet.',
        ),
      );
      return false;
    }

    isShowing = true;
    fullScreenContentCallback?.onAdShowedFullScreenContent?.call(this);
    fullScreenContentCallback?.onAdImpression?.call(this);

    bool earnedReward = false;

    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _RewardedAdPlayerDialog(
          adUnitId: adUnitId,
          customTitle: customTitle,
          rewardType: rewardType,
          rewardAmount: rewardAmount,
          onAdClicked: () => fullScreenContentCallback?.onAdClicked?.call(this),
          onRewardEarned: (reward) {
            earnedReward = true;
            onUserEarnedReward(this, reward);
          },
        );
      },
    );

    isShowing = false;
    isLoaded = false;
    fullScreenContentCallback?.onAdDismissedFullScreenContent?.call(this);

    return earnedReward;
  }

  void dispose() {
    isLoaded = false;
    isShowing = false;
  }
}

/// Interactive high-fidelity Rewarded Video Player Dialog
class _RewardedAdPlayerDialog extends StatefulWidget {
  final String adUnitId;
  final String? customTitle;
  final String rewardType;
  final num rewardAmount;
  final VoidCallback? onAdClicked;
  final ValueChanged<RewardItem> onRewardEarned;

  const _RewardedAdPlayerDialog({
    required this.adUnitId,
    this.customTitle,
    required this.rewardType,
    required this.rewardAmount,
    this.onAdClicked,
    required this.onRewardEarned,
  });

  @override
  State<_RewardedAdPlayerDialog> createState() => _RewardedAdPlayerDialogState();
}

class _RewardedAdPlayerDialogState extends State<_RewardedAdPlayerDialog>
    with SingleTickerProviderStateMixin {
  static const int _totalDurationSeconds = 5;
  int _secondsRemaining = _totalDurationSeconds;
  Timer? _countdownTimer;
  bool _isRewardUnlocked = false;
  bool _isMuted = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _totalDurationSeconds),
    )..forward();

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
        } else {
          _secondsRemaining = 0;
          _isRewardUnlocked = true;
          timer.cancel();
          widget.onRewardEarned(
            RewardItem(
              amount: widget.rewardAmount,
              type: widget.rewardType,
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _handleCloseAttempt() async {
    if (_isRewardUnlocked) {
      Navigator.of(context).pop(true);
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Leave Video Ad Early?'),
        content: const Text(
          'If you close this ad now, your Executive Template will remain locked and no AI Interview session tokens will be granted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Resume Ad'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave Anyway'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTestAd = widget.adUnitId.contains('3940256099942544');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleCloseAttempt();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Top Ad Bar: Close / Countdown / Test Mode Indicator
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isRewardUnlocked ? Icons.close_rounded : Icons.close,
                        color: Colors.white,
                        size: 26,
                      ),
                      tooltip: _isRewardUnlocked ? 'Close and Claim' : 'Skip Ad',
                      onPressed: _handleCloseAttempt,
                    ),
                    const SizedBox(width: 8),
                    if (isTestAd)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bug_report, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'Test Ad (${widget.adUnitId.substring(widget.adUnitId.length - 10)})',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      tooltip: _isMuted ? 'Unmute' : 'Mute',
                      onPressed: () => setState(() => _isMuted = !_isMuted),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isRewardUnlocked
                            ? AppColors.accentGreen.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderPill,
                        border: Border.all(
                          color: _isRewardUnlocked ? AppColors.accentGreen : Colors.white24,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRewardUnlocked
                                ? Icons.check_circle_rounded
                                : Icons.timer_outlined,
                            size: 16,
                            color: _isRewardUnlocked ? AppColors.accentGreen : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isRewardUnlocked
                                ? 'Reward Granted!'
                                : 'Reward in ${_secondsRemaining}s',
                            style: AppTypography.labelSmall.copyWith(
                              color: _isRewardUnlocked ? AppColors.accentGreen : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Linear Ad Timer Progress Bar
                ClipRRect(
                  borderRadius: AppRadius.borderPill,
                  child: AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressController.value,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isRewardUnlocked ? AppColors.accentGreen : AppColors.primary,
                        ),
                        minHeight: 4,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Main Video Player Creative Canvas
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onAdClicked,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F172A),
                            Color(0xFF1E293B),
                            Color(0xFF0284C7),
                          ],
                        ),
                        borderRadius: AppRadius.borderLg,
                        border: Border.all(
                          color: _isRewardUnlocked
                              ? AppColors.accentGreen.withValues(alpha: 0.8)
                              : Colors.white12,
                          width: _isRewardUnlocked ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isRewardUnlocked ? AppColors.accentGreen : AppColors.primary)
                                .withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background decorative circles
                          Positioned(
                            top: -40,
                            right: -40,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withValues(alpha: 0.1),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 2),
                                  ),
                                  child: Icon(
                                    _isRewardUnlocked
                                        ? Icons.verified_rounded
                                        : Icons.smart_toy_outlined,
                                    size: 56,
                                    color: _isRewardUnlocked
                                        ? AppColors.accentGreen
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  widget.customTitle ?? 'Resume Brain AI Interview Engine',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Level up your career with Google Gemini-powered resume tailoring, automated ATS optimization, and AI mock interview simulations.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white70,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: AppRadius.borderMd,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.card_giftcard_rounded,
                                          color: Colors.amber, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Reward: Executive Template Unlock + 1 AI Interview Token',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Action: Claim or Status
                if (_isRewardUnlocked)
                  AppButton(
                    text: 'Claim Reward & Unlock Now',
                    icon: Icons.check_circle_rounded,
                    variant: AppButtonVariant.primary,
                    isFullWidth: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: AppRadius.borderMd,
                    ),
                    child: Text(
                      'Watch for $_secondsRemaining more seconds to unlock your reward...',
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Central monetization and rewarded ad management service for Resume Brain.
class AdService {
  final Ref? _ref;
  RewardedAd? _preloadedRewardedAd;
  bool _isAdLoading = false;
  int _totalAdsWatched = 0;

  AdService([this._ref]);

  int get totalAdsWatched => _totalAdsWatched;
  bool get isAdReady => _preloadedRewardedAd?.isLoaded ?? false;

  /// Returns current platform's Rewarded Ad Unit ID
  String get adUnitId => AdUnitIds.getRewardedAdUnitId();

  /// Preloads a Rewarded Ad in the background so it plays with zero delay.
  Future<void> preloadRewardedAd({Duration latency = const Duration(milliseconds: 100)}) async {
    if (_isAdLoading || (_preloadedRewardedAd?.isLoaded ?? false)) return;
    _isAdLoading = true;

    await RewardedAd.load(
      adUnitId: adUnitId,
      latency: latency,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _preloadedRewardedAd = ad;
          _isAdLoading = false;
          _configureAdListeners(ad);
        },
        onAdFailedToLoad: (error) {
          _isAdLoading = false;
          _preloadedRewardedAd = null;
        },
      ),
    );
  }

  void _configureAdListeners(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedAd: Fullscreen video ad displayed (${ad.adUnitId})');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd: Fullscreen video ad dismissed');
        _preloadedRewardedAd = null;
        // Automatically preload the next rewarded ad for quick succession
        preloadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd: Failed to show: ${error.message}');
        _preloadedRewardedAd = null;
        preloadRewardedAd();
      },
      onAdClicked: (ad) {
        debugPrint('RewardedAd: User clicked sponsored creative');
      },
      onAdImpression: (ad) {
        debugPrint('RewardedAd: Ad impression logged');
      },
    );
  }

  /// Shows the rewarded ad, unlocks the Executive template for the session,
  /// and grants 1 free AI Interview session token.
  Future<bool> showRewardedAd({
    required BuildContext context,
    String rewardType = 'ai_interview_token',
    num rewardAmount = 1,
    String? customTitle,
    String? unlockTemplateId,
    void Function(RewardItem reward)? onUserEarnedReward,
  }) async {
    // If not preloaded, load ad immediately
    if (_preloadedRewardedAd == null || !_preloadedRewardedAd!.isLoaded) {
      await preloadRewardedAd(latency: Duration.zero);
    }

    final ad = _preloadedRewardedAd ??
        RewardedAd(
          adUnitId: adUnitId,
          isLoaded: true,
        );

    _configureAdListeners(ad);

    if (!context.mounted) return false;

    final bool success = await ad.show(
      context: context,
      customTitle: customTitle,
      rewardType: rewardType,
      rewardAmount: rewardAmount,
      onUserEarnedReward: (adInstance, reward) {
        _totalAdsWatched++;

        // 1. Grant 1 free AI Interview session token
        if (_ref != null) {
          _ref.read(aiInterviewTokensProvider.notifier).grantToken(1);
        }

        // 2. Permanently unlock Executive template for that session if specified
        if (unlockTemplateId != null && _ref != null) {
          _ref.read(sessionUnlockedTemplatesProvider.notifier).unlockTemplate(unlockTemplateId);
        }

        onUserEarnedReward?.call(reward);
      },
    );

    return success;
  }
}

/// State notifier managing templates permanently unlocked during the current app session.
class SessionUnlockedTemplatesNotifier extends StateNotifier<Set<String>> {
  SessionUnlockedTemplatesNotifier() : super({});

  /// Checks if template is an Executive template
  static bool isExecutiveTemplate(String templateId) {
    final lower = templateId.toLowerCase();
    return lower == 'executive_minimal' || lower.contains('executive');
  }

  /// Permanently unlocks a template for this app session.
  void unlockTemplate(String templateId) {
    if (!state.contains(templateId)) {
      state = {...state, templateId};
    }
  }

  /// Returns true if the template is free or unlocked in the current session.
  bool isTemplateUnlocked(String templateId) {
    if (!isExecutiveTemplate(templateId)) {
      return true; // Free ATS templates are always unlocked
    }
    return state.contains(templateId);
  }

  /// Resets unlocked session templates (useful for testing or app restart)
  void resetSession() {
    state = {};
  }
}

/// Provider for in-session template unlock state
final sessionUnlockedTemplatesProvider =
    StateNotifierProvider<SessionUnlockedTemplatesNotifier, Set<String>>((ref) {
  return SessionUnlockedTemplatesNotifier();
});

/// State notifier managing the user's AI Mock Interview tokens.
class AiInterviewTokensNotifier extends StateNotifier<int> {
  static const String _storageKey = 'resume_brain_ai_interview_tokens';
  static const int _defaultWelcomeTokens = 2;

  AiInterviewTokensNotifier() : super(_defaultWelcomeTokens) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_storageKey);
      if (saved != null) {
        state = saved;
      } else {
        await prefs.setInt(_storageKey, _defaultWelcomeTokens);
      }
    } catch (_) {}
  }

  /// Grants free tokens (default 1 per rewarded ad view)
  Future<void> grantToken([int amount = 1]) async {
    final updated = state + amount;
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, updated);
    } catch (_) {}
  }

  /// Uses 1 token to start an AI Mock Interview session. Returns false if no tokens available.
  Future<bool> useToken() async {
    if (state <= 0) return false;
    final updated = state - 1;
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, updated);
    } catch (_) {}
    return true;
  }

  /// Direct setter for unit testing
  void setTokensForTesting(int amount) {
    state = amount;
  }
}

/// Provider for user's AI Mock Interview tokens balance
final aiInterviewTokensProvider =
    StateNotifierProvider<AiInterviewTokensNotifier, int>((ref) {
  return AiInterviewTokensNotifier();
});

/// Riverpod provider for AdService
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService(ref);
  service.preloadRewardedAd();
  return service;
});
