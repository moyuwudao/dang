import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  Future<User?> getCurrentUser() async {
    return null;
  }

  Future<bool> isLoggedIn() async {
    return false;
  }
}
