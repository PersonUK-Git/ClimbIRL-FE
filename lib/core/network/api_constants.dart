class ApiConstants {
  ApiConstants._();

  static const String _devBaseUrl = 'http://192.168.1.68:5000/api';
  static const String _prodBaseUrl = 'https://api.climbirl.trackittoo.com/api';

  // Toggle this to switch between environments
  // static const bool _isProd = true;
  static const bool _isProd = false;
  static const String baseUrl = _isProd ? _prodBaseUrl : _devBaseUrl;

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';

  // Task endpoints
  static const String tasks = '$baseUrl/tasks';
  static String completeTask(String id) => '$tasks/$id/complete';
  static String verifyTask(String id) => '$tasks/$id/verify';

  // User endpoints
  static const String profile = '$baseUrl/users/profile';
  static const String milestones = '$baseUrl/users/milestones';

  // Leaderboard endpoints
  static const String leaderboard = '$baseUrl/leaderboard';
  static String getLeaderboardWithPeriod(String period) => '$leaderboard?period=$period';

  // Legal & Static pages
  static final String privacyPolicy = baseUrl.replaceAll('/api', '') + '/privacy';
  static final String termsOfService = baseUrl.replaceAll('/api', '') + '/terms';
  static final String deleteAccountInfo = baseUrl.replaceAll('/api', '') + '/delete-account';

}

