import 'package:zirofit_fl/data/models/user.dart';

/// Abstract interface for authentication operations.
abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
  });

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
  });

  Future<void> signOut();

  Future<User?> getCurrentUser();

  Future<Map<String, dynamic>> refreshToken(String refreshToken);
}
