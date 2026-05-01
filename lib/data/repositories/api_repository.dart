import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_constants.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/achievement_model.dart';

class ApiRepository {
  final Logger _logger = Logger();
  static const String _tokenKey = 'auth_token';
  String? _cachedToken;

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'x-timezone-offset': DateTime.now().timeZoneOffset.inMinutes.toString(),
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth Methods
  Future<UserModel?> register(UserModel user) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: _getHeaders(null),
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await saveToken(token);
        return UserModel.fromJson(data);
      } else {
        _logger.e('Failed to register: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error during registration', error: e);
      return null;
    }
  }

  Future<bool> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.sendOtp),
        headers: _getHeaders(null),
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _logger.e('Failed to send OTP: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error sending OTP', error: e);
      return false;
    }
  }

  Future<UserModel?> verifyOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.verifyOtp),
        headers: _getHeaders(null),
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await saveToken(token);
        return UserModel.fromJson(data);
      } else {
        _logger.e('Failed to verify OTP: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error verifying OTP', error: e);
      return null;
    }
  }

  // User Profile
  Future<UserModel?> getProfile() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.profile),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to fetch profile: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching profile', error: e);
      return null;
    }
  }

  Future<List<AchievementModel>> getAchievements() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.profile}/achievements'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => AchievementModel.fromJson(json)).toList();
      } else {
        _logger.e('Failed to fetch achievements: ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching achievements', error: e);
      return [];
    }
  }

  Future<UserModel?> updateProfile(UserModel user) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse(ApiConstants.profile),
        headers: _getHeaders(token),
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to update profile: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error updating profile', error: e);
      return null;
    }
  }

  // Task Methods
  Future<List<TaskModel>> getTasks() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.tasks),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        _logger.e('Failed to fetch tasks: ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching tasks', error: e);
      return [];
    }
  }

  Future<TaskModel?> createTask(TaskModel task) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(ApiConstants.tasks),
        headers: _getHeaders(token),
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 201) {
        return TaskModel.fromJson(jsonDecode(response.body));
      } else {
        _logger.e('Failed to create task: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error creating task', error: e);
      return null;
    }
  }

  Future<UserModel?> completeTask(String taskId) async {
    try {
      final token = await getToken();
      final response = await http.patch(
        Uri.parse(ApiConstants.completeTask(taskId)),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The backend returns { task, user }
        return UserModel.fromJson(data['user']);
      }
    } catch (e) {
      _logger.e('Error completing task', error: e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifyTask({
    required String taskId,
    String? imageBase64,
    String? proofNote,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse(ApiConstants.verifyTask(taskId)),
        headers: _getHeaders(token),
        body: jsonEncode({
          if (imageBase64 != null) 'imageBase64': imageBase64,
          if (proofNote != null) 'proofNote': proofNote,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'task': TaskModel.fromJson(data['task']),
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['reason'] ?? data['message'] ?? 'Verification failed');
      }
    } catch (e) {
      _logger.e('Error verifying task', error: e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> rerollTask(String taskId, {bool watchAd = false}) async {
    try {
      final token = await getToken();
      final response = await http.patch(
        Uri.parse('${ApiConstants.tasks}/$taskId/reroll'),
        headers: _getHeaders(token),
        body: jsonEncode({'watchAd': watchAd}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'task': TaskModel.fromJson(data['task']),
          'user': UserModel.fromJson(data['user']),
        };
      } else {
        _logger.e('Failed to reroll task: ${response.body}');
        return null;
      }
    } catch (e) {
      _logger.e('Error rerolling task', error: e);
      return null;
    }
  }


  Future<bool> deleteTask(String taskId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.tasks}/$taskId'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _logger.e('Failed to delete task: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error deleting task', error: e);
      return false;
    }
  }

  // Leaderboard
  Future<List<UserModel>> getLeaderboard({required String period}) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(ApiConstants.getLeaderboardWithPeriod(period)),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => UserModel.fromJson(json)).toList();
      } else {
        _logger.e('Failed to fetch leaderboard: ${response.body}');
        return [];
      }
    } catch (e) {
      _logger.e('Error fetching leaderboard', error: e);
      return [];
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse(ApiConstants.profile),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        await clearToken();
        return true;
      } else {
        _logger.e('Failed to delete account: ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('Error deleting account', error: e);
      return false;
    }
  }
}

