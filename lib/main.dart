import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/utils/update_service.dart';
import 'core/ads/ad_manager.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  // Initialize Notification Service
  NotificationService().initialize().catchError((e) {
    print('Error initializing NotificationService: $e');
  });
  
  // Initialize Mobile Ads SDK
  final initStatus = MobileAds.instance.initialize();
  
  // Register this device as a test device to avoid "No Fill" errors during development
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(testDeviceIds: ['098B5E17F004EDFEDF3AAC1AF91FDF17']),
  );
  
  // Preload rewarded ad
  initStatus.then((_) => AdManager.instance.loadRewardedAd());

  // Check for updates on Google Play (Android only)
  UpdateService.checkForUpdate();
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Prefer portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ClimbIRLApp());
}
