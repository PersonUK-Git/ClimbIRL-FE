import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/repositories/api_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();
  final ApiRepository _apiRepository = ApiRepository();

  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.i('User granted permission');
        
        final token = await _messaging.getToken();
        print('NotificationService: Initial FCM Token: $token');
        
        // Initialize local notifications for foreground
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initializationSettings =
            InitializationSettings(android: initializationSettingsAndroid);
        await _localNotifications.initialize(initializationSettings);
        
        // Initialize timezones
        tz.initializeTimeZones();

        // Get token and save to backend
        await updateToken();



        // Listen for token refresh
        _messaging.onTokenRefresh.listen((token) {
          _logger.i('FCM Token refreshed: $token');
          updateToken(token);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _logger.i('Got a message in the foreground!');
          if (message.notification != null) {
            _showLocalNotification(message.notification!);
          }
        });
      } else {
        _logger.w('User declined or has not accepted permission');
      }
    } catch (e) {
      _logger.e('Error during NotificationService initialization', error: e);
    }
  }

  Future<void> updateToken([String? token]) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken != null) {
        _logger.i('Saving FCM Token to backend: $fcmToken');
        final user = await _apiRepository.getProfile();
        if (user != null) {
          final updatedUser = user.copyWith(fcmToken: fcmToken);
          await _apiRepository.updateProfile(updatedUser);
          _logger.i('FCM Token saved successfully!');
        } else {
          _logger.w('Could not get profile to update FCM token');
        }
      } else {
        _logger.w('FCM Token is null');
      }
    } catch (e) {
      _logger.e('Error updating FCM token in backend', error: e);
    }
  }

  Future<void> _showLocalNotification(RemoteNotification notification) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Channel for daily task reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
    );
  }


}
