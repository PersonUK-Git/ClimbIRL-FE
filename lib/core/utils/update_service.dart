import 'dart:io';
import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';

class UpdateService {
  static final Logger _logger = Logger();

  /// Checks for available updates on the Google Play Store.
  /// This is an Android-only feature.
  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) {
      _logger.d('In-app updates are only supported on Android.');
      return;
    }

    try {
      _logger.i('Checking for app updates...');
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        _logger.i('Update available! Priority: ${info.updatePriority}');

        // If the update priority is high (e.g. >= 4), perform an immediate update.
        // Otherwise, suggest a flexible update.
        if (info.immediateUpdateAllowed) {
          _logger.i('Starting immediate update...');
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          _logger.i('Starting flexible update...');
          await InAppUpdate.startFlexibleUpdate();
          
          // Once downloaded, prompt the user to install
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        _logger.d('App is up to date.');
      }
    } catch (e) {
      _logger.e('Failed to check for updates: $e');
    }
  }
}
