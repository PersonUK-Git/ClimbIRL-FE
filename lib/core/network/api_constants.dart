class ApiConstants {
  ApiConstants._();

  // Machine's local IP address for physical device connectivity
  static const String baseUrl = 'http://192.168.1.68:5000/api';

  // Auth endpoints
  static const String register = '$baseUrl/auth/register';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';

  // Task endpoints
  static const String tasks = '$baseUrl/tasks';
  static String completeTask(String id) => '$tasks/$id/complete';

  // User endpoints
  static const String profile = '$baseUrl/users/profile';

  // Leaderboard endpoints
  static const String leaderboard = '$baseUrl/leaderboard';
  static String getLeaderboardWithPeriod(String period) => '$leaderboard?period=$period';
}
