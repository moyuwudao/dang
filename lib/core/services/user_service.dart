import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

class UserService {
  Future<User?> getUserProfile() async {
    return null;
  }

  Future<void> updateUserProfile(User user) async {
    // TODO: Implement
  }
}
