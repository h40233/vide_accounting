import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ApiService _api;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthNotifier(this._api) : super(const AsyncValue.data(null)) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token != null) {
      try {
        final response = await _api.getMe();
        state = AsyncValue.data(UserModel.fromJson(response.data));
      } catch (e) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> login() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      
      if (idToken == null) return false;

      final response = await _api.loginGoogle(idToken);
      final String token = response.data['access_token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);

      final userResponse = await _api.getMe();
      state = AsyncValue.data(UserModel.fromJson(userResponse.data));
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    state = const AsyncValue.data(null);
  }
}
