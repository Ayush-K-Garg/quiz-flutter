import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class UserApi {
  static const String host = '10.0.2.2:3000';
  static const String basePath = '/api/users';

  // Helper to get the Firebase ID Token
  Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      print('🔑 Retrieved Firebase ID Token: $token');
      return token;
    }
    print('⚠️ No logged in user found when retrieving token');
    return null;
  }

  Future<List<dynamic>> searchUsers(String query) async {
    final token = await getIdToken();
    if (token == null) throw Exception('User not logged in');

    print('🔍 Searching users with query: "$query"');

    final uri = Uri.http(host, '$basePath/search', {'query': query});
    print('🌐 Sending GET request to: $uri');

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      print('✅ Found ${users.length} users');
      return users;
    } else {
      print('❌ Failed to search users with status code: ${response.statusCode}');
      throw Exception('Failed to search users');
    }
  }

  Future<List<dynamic>> getSuggestedUsers() async {
    final token = await getIdToken();
    if (token == null) throw Exception('User not logged in');

    final uri = Uri.http(host, '$basePath/suggested');
    print('🌐 Fetching suggested users from: $uri');

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    print('📥 Response status: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> users = json.decode(response.body);
      print('✅ Retrieved ${users.length} suggested users');
      return users;
    } else {
      print('❌ Failed to fetch suggested users with status code: ${response.statusCode}');
      throw Exception('Failed to fetch suggested users');
    }
  }
}
