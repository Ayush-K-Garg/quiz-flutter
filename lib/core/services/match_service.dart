// lib/core/services/match_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/data/models/question_model.dart';

class MatchService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<String?> _getFirebaseToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not logged in');
    return await user.getIdToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getFirebaseToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// ✅ CREATE ROOM
  Future<MatchRoom> createMatchRoom({
    required String category,
    required String difficulty,
    required int amount,
    required String mode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/match/create');
    final payload = {
      'category': category,
      'difficulty': difficulty,
      'amount': amount,
      'mode': mode,
    };

    print('\n🔹 [MatchService] 🔹 CREATE ROOM');
    print('➡️ POST $uri');
    print('📦 Payload: $payload');

    try {
      final headers = await _getHeaders();

      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MatchRoom.fromJson(data);
      } else {
        throw Exception('❌ Backend error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 Exception during createMatchRoom: $e');
      rethrow;
    }
  }

  /// ✅ JOIN ROOM
  Future<MatchRoom> joinMatchRoom(String roomId) async {
    final uri = Uri.parse('$baseUrl/api/match/join-room/$roomId');

    print('\n🔹 [MatchService] 🔹 JOIN ROOM');
    print('➡️ POST $uri');

    try {
      final headers = await _getHeaders();

      final response = await http.post(uri, headers: headers);

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MatchRoom.fromJson(data);
      } else {
        throw Exception('❌ Failed to join room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 Exception during joinMatchRoom: $e');
      rethrow;
    }
  }

  /// ✅ SUBMIT ANSWERS
  Future<void> submitAnswers({
    required String roomId,
    required Map<String, String> answers,
    required int score,
  }) async {
    final uri = Uri.parse('$baseUrl/api/match/answer');
    final payload = {
      'roomId': roomId,
      'answers': answers,
      'score': score,
    };

    print('\n🔹 [MatchService] 🔹 SUBMIT ANSWERS');
    print('➡️ POST $uri');
    print('📦 Payload: $payload');

    try {
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('❌ Failed to submit answers: ${response.statusCode} - ${response.body}');
      } else {
        print('✅ Answers submitted successfully');
      }
    } catch (e) {
      print('🚨 Exception during submitAnswers: $e');
      rethrow;
    }
  }

  /// ✅ GET MATCH ROOM STATUS
  Future<MatchRoom> getMatchRoom(String roomId) async {
    final uri = Uri.parse('$baseUrl/api/match/room/$roomId');

    print('\n🔹 [MatchService] 🔹 GET MATCH ROOM');
    print('➡️ GET $uri');

    try {
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MatchRoom.fromJson(data);
      } else {
        throw Exception('❌ Failed to fetch match room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 Exception during getMatchRoom: $e');
      rethrow;
    }
  }

  /// ✅ GET LEADERBOARD
  Future<List<Map<String, dynamic>>> getLeaderboard(String roomId) async {
    final uri = Uri.parse('$baseUrl/api/match/leaderboard/$roomId');

    print('\n🔹 [MatchService] 🔹 GET LEADERBOARD');
    print('➡️ GET $uri');

    try {
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('❌ Failed to fetch leaderboard: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 Exception during getLeaderboard: $e');
      rethrow;
    }
  }

  /// ✅ PRACTICE MODE - Dummy Data (for now)
  Future<List<Question>> generatePracticeQuestions({
    required String category,
    required String difficulty,
    required int amount,
  }) async {
    final uri = Uri.parse('$baseUrl/api/quiz/questions').replace(queryParameters: {
      'category': category,
      'difficulty': difficulty,
      'amount': amount.toString(),
    });

    final headers = await _getHeaders();

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((q) => Question.fromJson(q)).toList();
    } else {
      throw Exception('Failed to fetch practice questions');
    }
  }

}
