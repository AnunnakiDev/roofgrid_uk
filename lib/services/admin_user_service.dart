import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AdminUserService {
  static const apiBaseUrl = 'https://api-gbtz2ngl6q-uc.a.run.app';

  final FirebaseAuth _auth;

  AdminUserService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Future<String> _requireIdToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AdminUserServiceException('You must be signed in as an admin.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw AdminUserServiceException('Could not obtain an auth token.');
    }
    return token;
  }

  Future<void> deleteUser(String targetUserId) async {
    final idToken = await _requireIdToken();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/adminDeleteUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'data': {'targetUserId': targetUserId},
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    final message = _extractErrorMessage(response.body) ??
        'Failed to delete user (HTTP ${response.statusCode}).';
    throw AdminUserServiceException(message);
  }

  Future<String> createUser({
    required String email,
    required String password,
  }) async {
    final idToken = await _requireIdToken();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/adminCreateUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'data': {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final userId = data['userId'] as String?;
      if (userId == null || userId.isEmpty) {
        throw AdminUserServiceException('User created but no userId returned.');
      }
      return userId;
    }

    final message = _extractErrorMessage(response.body) ??
        'Failed to create user (HTTP ${response.statusCode}).';
    throw AdminUserServiceException(message);
  }

  String? _extractErrorMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final error = data['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
    } catch (_) {
      // Ignore parse errors and fall back to generic message.
    }
    return null;
  }
}

class AdminUserServiceException implements Exception {
  final String message;

  AdminUserServiceException(this.message);

  @override
  String toString() => message;
}