import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'dart:async';

class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  // Test Ad Unit IDs (use real ones in production)
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-6662394717507972/5944728919';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  Future<void> loadRewardedAd() async {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    
    _isRewardedAdLoading = true;
    
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({required Function() onRewardEarned}) async {
    if (_rewardedAd == null) {
      await loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    bool earned = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        print('[AdManager] Ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); 
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('[AdManager] Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    print('[AdManager] Showing ad...');
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('[AdManager] Reward earned!');
        earned = true;
        onRewardEarned();
      },
    );

    return completer.future;
  }
}
