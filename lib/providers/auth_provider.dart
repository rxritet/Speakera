import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mock_data.dart';

/// AuthProvider manages user authentication state
/// It handles login, logout, and maintains the current user session
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Login with a user ID from mock data
  /// This is a demo implementation - in production, this would call an API
  Future<bool> login(String userId) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to find the user in mock admins
      UserModel? user = mockAdmins.cast<UserModel?>().firstWhere(
            (u) => u?.id == userId,
            orElse: () => null,
          );

      // If not found in admins, try students
      user ??= mockStudents.cast<UserModel?>().firstWhere(
            (u) => u?.id == userId,
            orElse: () => null,
          );

      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Login with email and password
  /// This is a demo implementation - in production, this would call an API
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to find user by email in mock data
      UserModel? user;

      // Check admins
      for (var admin in mockAdmins) {
        if (admin.email == email) {
          user = admin;
          break;
        }
      }

      // Check students if not found in admins
      if (user == null) {
        for (var student in mockStudents) {
          if (student.email == email) {
            user = student;
            break;
          }
        }
      }

      if (user != null) {
        // In a real app, verify the password
        _currentUser = user;
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Register a new user account
  /// Returns null on success, or an error message string on failure
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      // Check if email is already taken
      final emailLower = email.toLowerCase();
      for (var admin in mockAdmins) {
        if (admin.email.toLowerCase() == emailLower) {
          return 'An account with this email already exists.';
        }
      }
      for (var student in mockStudents) {
        if (student.email.toLowerCase() == emailLower) {
          return 'An account with this email already exists.';
        }
      }

      // Generate a unique ID
      final prefix = role == UserRole.admin ? 'a' : 's';
      final count = role == UserRole.admin
          ? mockAdmins.length
          : mockStudents.length;
      final newId = '$prefix${count + 1}';

      // Create the new user
      final newUser = UserModel(
        id: newId,
        name: name,
        email: email,
        role: role,
      );

      // Add to the appropriate mock list
      if (role == UserRole.admin) {
        mockAdmins.add(newUser);
      } else {
        mockStudents.add(newUser);
      }

      // Auto-login after registration
      _currentUser = newUser;
      notifyListeners();
      return null; // success
    } catch (e) {
      debugPrint('Registration error: $e');
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Logout the current user
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  /// Update the current user
  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Get list of all available users for demo purposes
  List<UserModel> getAllUsers() {
    return [...mockAdmins, ...mockStudents];
  }

  /// Get list of admin users
  List<UserModel> getAdmins() {
    return [...mockAdmins];
  }

  /// Get list of student users
  List<UserModel> getStudents() {
    return [...mockStudents];
  }
}
