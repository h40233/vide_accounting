import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  final Dio dio = Dio(BaseOptions(baseUrl: baseUrl));

  ApiService() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Response> loginGoogle(String token) async {
    return dio.post('/auth/google?token=$token');
  }

  Future<Response> getMe() async {
    return dio.get('/me');
  }

  Future<Response> getAccounts() async {
    return dio.get('/accounts');
  }

  Future<Response> createAccount(Map<String, dynamic> data) async {
    return dio.post('/accounts', data: data);
  }

  Future<Response> getCategories() async {
    return dio.get('/categories');
  }

  Future<Response> getTransactions() async {
    return dio.get('/transactions');
  }

  Future<Response> createTransaction(Map<String, dynamic> data) async {
    return dio.post('/transactions', data: data);
  }

  // --- Groups ---
  Future<Response> getMyGroups() async {
    return dio.get('/groups');
  }

  Future<Response> createGroup(Map<String, dynamic> data) async {
    return dio.post('/groups', data: data);
  }
  
  Future<Response> inviteToGroup(String groupId, String email) async {
    return dio.post('/groups/$groupId/invite', queryParameters: {'email': email});
  }

  // --- Schedules ---
  Future<Response> getSchedules() async {
    return dio.get('/schedules');
  }

  Future<Response> createSchedule(Map<String, dynamic> data) async {
    return dio.post('/schedules', data: data);
  }

  Future<Response> deleteSchedule(String id) async {
    return dio.delete('/schedules/$id');
  }

  // --- Notifications ---
  Future<Response> getNotifications() async {
    return dio.get('/notifications');
  }

  Future<Response> markNotificationRead(String id) async {
    return dio.patch('/notifications/$id/read');
  }
}

