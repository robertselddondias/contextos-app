import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A comprehensive service for managing ads on iOS and Android platforms.
/// 
/// This class handles initialization, loading, and displaying of various ad formats
/// including banners, interstitials, and rewarded ads in a cross-platform way.
class AdManager {
  // Singleton pattern
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // Initialization state tracking
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Premium status tracking
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // Test mode flag (for development)
  final bool _useTestAds = kDebugMode;

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Ad states
  bool _isBannerAdLoaded = false;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdReady => _interstitialAd != null;
  bool get isRewardedAdReady => _rewardedAd != null;

  // Ad tracking
  int _interstitialAdCount = 0;
  DateTime? _lastInterstitialShown;
  int _interstitialFrequency = 3; // Show after every X game completions

  // Test ad unit IDs
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Production ad unit IDs
  // Replace these with your actual production ad unit IDs
  static const String _iosBannerAdUnitId = 'ca-app-pub-4458700759850229/6473230385';
  static const String _androidBannerAdUnitId = 'ca-app-pub-4458700759850229/7238682990';

  static const String _iosInterstitialAdUnitId = 'ca-app-pub-4458700759850229/5755178538';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-4458700759850229/5850214168';

  static const String _iosRewardedAdUnitId = 'ca-app-pub-4458700759850229/2533985374';
  static const String _androidRewardedAdUnitId = 'ca-app-pub-4458700759850229/4442096867';

  // Getters for ad unit IDs based on platform and test mode
  String get bannerAdUnitId {
    if (_useTestAds) return _testBannerAdUnitId;
    return Platform.isIOS ? _iosBannerAdUnitId : _androidBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    if (_useTestAds) return _testInterstitialAdUnitId;
    return Platform.isIOS ? _iosInterstitialAdUnitId : _androidInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    if (_useTestAds) return _testRewardedAdUnitId;
    return Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId;
  }

  /// Initialize the ad service.
  ///
  /// Should be called early in the app lifecycle, typically in main.dart.
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('AdService: Already initialized');
      return;
    }

    try {
      // Initialize the Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Set up app open ads (optional)
      // MobileAds.instance.updateRequestConfiguration(
      //   RequestConfiguration(testDeviceIds: ['YOUR_TEST_DEVICE_ID']),
      // );

      // Load user premium status
      await _loadPremiumStatus();

      // Skip further ad loading if user is premium
      if (_isPremium) {
        _isInitialized = true;
        debugPrint('AdService: Initialized in premium mode (ads disabled)');
        return;
      }

      // Load interstitial and rewarded ads
      _loadInterstitialAd();
      _loadRewardedAd();

      // Load settings
      await _loadSettings();

      _isInitialized = true;
      debugPrint('AdService: Initialized successfully');
    } catch (e) {
      debugPrint('AdService: Error during initialization: $e');
      // Mark as initialized anyway to prevent repeated initialization attempts
      _isInitialized = true;
    }
  }

  /// Load user premium status from shared preferences.
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('premium_user') ?? false;
      debugPrint('AdService: Premium status loaded: $_isPremium');
    } catch (e) {
      debugPrint('AdService: Error loading premium status: $e');
      _isPremium = false;
    }
  }

  /// Load ad-related settings from shared preferences.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load interstitial frequency setting
      _interstitialFrequency = prefs.getInt('interstitial_frequency') ?? 3;

      // Load interstitial ad count
      _interstitialAdCount = prefs.getInt('interstitial_ad_count') ?? 0;

      // Load last shown timestamp
      final lastShownStr = prefs.getString('last_interstitial_shown');
      if (lastShownStr != null) {
        _lastInterstitialShown = DateTime.parse(lastShownStr);
      }

      debugPrint('AdService: Settings loaded');
    } catch (e) {
      debugPrint('AdService: Error loading settings: $e');
      // Use defaults if settings couldn't be loaded
      _interstitialFrequency = 3;
      _interstitialAdCount = 0;
      _lastInterstitialShown = null;
    }
  }

  /// Save ad-related settings to shared preferences.
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save interstitial ad count
      await prefs.setInt('interstitial_ad_count', _interstitialAdCount);

      // Save last shown timestamp
      if (_lastInterstitialShown != null) {
        await prefs.setString('last_interstitial_shown', _lastInterstitialShown!.toIso8601String());
      }

      debugPrint('AdService: Settings saved');
    } catch (e) {
      debugPrint('AdService: Error saving settings: $e');
    }
  }

  /// Update user premium status.
  ///
  /// Use this when a user purchases premium features or removes ads.
  Future<void> setPremiumStatus(bool isPremium) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premium_user', isPremium);
      _isPremium = isPremium;

      // Dispose of all ads if user upgraded to premium
      if (isPremium) {
        _disposeBannerAd();
        _disposeInterstitialAd();
        _disposeRewardedAd();
      }

      debugPrint('AdService: Premium status updated: $isPremium');
    } catch (e) {
      debugPrint('AdService: Error updating premium status: $e');
    }
  }

  /// Load a banner ad.
  ///
  /// This method should be called when you want to display a banner ad.
  /// The result can be accessed via isBannerAdLoaded property.
  Future<void> loadBannerAd({AdSize? size}) async {
    if (_isPremium) return;
    if (!_isInitialized) await initialize();

    // Dispose of any existing banner ad
    _disposeBannerAd();

    try {
      // Use standard banner size if not specified
      final adSize = size ?? AdSize.banner;

      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('AdService: Banner ad loaded');
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('AdService: Banner ad failed to load: ${error.message}');
            ad.dispose();
            _bannerAd = null;
            _isBannerAdLoaded = false;

            // Retry loading after a delay
            Future.delayed(const Duration(minutes: 1), () {
              if (!_isPremium) loadBannerAd(size: size);
            });
          },
          onAdOpened: (ad) => debugPrint('AdService: Banner ad opened'),
          onAdClosed: (ad) => debugPrint('AdService: Banner ad closed'),
          onAdImpression: (ad) => debugPrint('AdService: Banner ad impression'),
        ),
      );

      await _bannerAd!.load();
      debugPrint('AdService: Banner ad load requested');
    } catch (e) {
      debugPrint('AdService: Error loading banner ad: $e');
      _isBannerAdLoaded = false;
      _bannerAd = null;
    }
  }

  /// Get the current banner ad.
  ///
  /// Returns null if no banner ad is loaded or user is premium.
  BannerAd? getBannerAd() {
    if (_isPremium) return null;
    return _bannerAd;
  }

  /// Dispose of the current banner ad.
  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  /// Load an interstitial ad.
  ///
  /// This method is called automatically during initialization and after
  /// an interstitial ad is shown.
  void _loadInterstitialAd() {
    if (_isPremium) return;
    if (!_isInitialized && !kDebugMode) return;

    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            debugPrint('AdService: Interstitial ad loaded');

            // Set up full-screen content callback
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('AdService: Interstitial ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('AdService: Interstitial ad dismissed');
                ad.dispose();
                _interstitialAd = null;

                // Reload ad for next use
                _loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AdService: Interstitial ad failed to show: ${error.message}');
                ad.dispose();
                _interstitialAd = null;

                // Reload ad for next use
                _loadInterstitialAd();
              },
              onAdImpression: (ad) {
                debugPrint('AdService: Interstitial ad impression');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('AdService: Interstitial ad failed to load: ${error.message}');
            _interstitialAd = null;

            // Retry loading after a delay
            Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
          },
        ),
      );

      debugPrint('AdService: Interstitial ad load requested');
    } catch (e) {
      debugPrint('AdService: Error loading interstitial ad: $e');
      _interstitialAd = null;
    }
  }

  /// Dispose of the current interstitial ad.
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  /// Load a rewarded ad.
  ///
  /// This method is called automatically during initialization and after
  /// a rewarded ad is shown.
  void _loadRewardedAd() {
    if (_isPremium) return;
    if (!_isInitialized && !kDebugMode) return;

    try {
      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            debugPrint('AdService: Rewarded ad loaded');

            // Set up full-screen content callback
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('AdService: Rewarded ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('AdService: Rewarded ad dismissed');
                ad.dispose();
                _rewardedAd = null;

                // Reload ad for next use
                _loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AdService: Rewarded ad failed to show: ${error.message}');
                ad.dispose();
                _rewardedAd = null;

                // Reload ad for next use
                _loadRewardedAd();
              },
              onAdImpression: (ad) {
                debugPrint('AdService: Rewarded ad impression');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('AdService: Rewarded ad failed to load: ${error.message}');
            _rewardedAd = null;

            // Retry loading after a delay
            Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
          },
        ),
      );

      debugPrint('AdService: Rewarded ad load requested');
    } catch (e) {
      debugPrint('AdService: Error loading rewarded ad: $e');
      _rewardedAd = null;
    }
  }

  /// Dispose of the current rewarded ad.
  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  /// Show an interstitial ad.
  ///
  /// Returns true if the ad was shown, false otherwise.
  /// This method respects frequency capping and ensures a minimum time between ads.
  Future<bool> showInterstitial() async {
    if (_isPremium || _interstitialAd == null) return false;

    // Increment counter for frequency capping
    _interstitialAdCount++;
    await _saveSettings();

    // Check frequency cap
    if (_interstitialAdCount % _interstitialFrequency != 0) {
      return false;
    }

    // Check minimum time between ads (1 minute)
    if (_lastInterstitialShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialShown!);
      if (timeSinceLastAd.inMinutes < 1) {
        return false;
      }
    }

    // Show the ad
    try {
      await _interstitialAd!.show();
      _lastInterstitialShown = DateTime.now();
      await _saveSettings();
      debugPrint('AdService: Interstitial ad shown');
      return true;
    } catch (e) {
      debugPrint('AdService: Error showing interstitial ad: $e');
      // Reload after error
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _loadInterstitialAd();
      return false;
    }
  }

  /// Called to notify the service about a game completion for interstitial frequency calculations.
  ///
  /// Returns true if an interstitial ad was shown, false otherwise.
  Future<bool> notifyGameCompleted() async {
    if (_isPremium) return false;
    if (!_isInitialized) await initialize();

    return showInterstitial();
  }

  /// Show a rewarded ad.
  ///
  /// Returns true if the user earned the reward, false otherwise.
  /// Optionally accepts a callback to handle the reward.
  Future<bool> showRewardedAd({Function(RewardItem)? onRewarded}) async {
    if (_isPremium || _rewardedAd == null) return false;

    final completer = Completer<bool>();

    try {
      await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        // Call the reward callback if provided
        if (onRewarded != null) {
          onRewarded(reward);
        }

        debugPrint('AdService: User earned reward: ${reward.amount} ${reward.type}');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      // The fullScreenContentCallback will handle ad closing and errors

    } catch (e) {
      debugPrint('AdService: Error showing rewarded ad: $e');

      // Reload after error
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _loadRewardedAd();

      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  /// Set the frequency of interstitial ads (how many game completions between ads).
  Future<void> setInterstitialFrequency(int frequency) async {
    try {
      if (frequency < 1) frequency = 1;

      _interstitialFrequency = frequency;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('interstitial_frequency', frequency);

      debugPrint('AdService: Interstitial frequency set to $frequency');
    } catch (e) {
      debugPrint('AdService: Error setting interstitial frequency: $e');
    }
  }

  /// Request a specific banner ad size for the current screen.
  /// 
  /// Calculates and returns the best banner ad size for the current device screen.
  Future<AdSize> getAdaptiveBannerAdSize(double width) async {
    // Use adaptive banner if available
    if (!_isPremium) {
      try {
        final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            width.truncate());

        if (adaptiveSize != null) {
          return adaptiveSize;
        }
      } catch (e) {
        debugPrint('AdService: Error getting adaptive banner size: $e');
      }
    }

    // Fallback to standard banner
    return AdSize.banner;
  }

  /// Clean up all ad resources.
  ///
  /// Call this method when the app is being closed or when ads are no longer needed.
  void dispose() {
    _disposeBannerAd();
    _disposeInterstitialAd();
    _disposeRewardedAd();
    debugPrint('AdService: Disposed all ad resources');
  }
}
