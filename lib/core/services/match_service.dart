import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/data/models/question_model.dart';
import 'socket_service.dart';

class MatchService {
  final socketService = SocketService(); // Singleton or inject

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

  /// 🔹 CREATE MATCH ROOM (Custom)
  Future<MatchRoom> createMatchRoom({
    required String category,
    required String difficulty,
    required int amount,
    required String mode,
    String? customRoomId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/match/create');
    final payload = {
      'category': category,
      'difficulty': difficulty,
      'amount': amount,
      'mode': mode,
      if (customRoomId != null) 'customRoomId': customRoomId,
    };

    print('\n🔹 [MatchService] 🔹 CREATE MATCH ROOM');
    print('➡️ POST $uri');
    print('📦 Payload: $payload');

    try {
      final headers = await _getHeaders();
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final room = MatchRoom.fromJson(data);

        print('🎉 [MatchService] Room Created: ${room.id}');
        socketService.emit('joinRoom', {'roomId': room.id});
        print('📡 [Socket] joinRoom emitted for ${room.id}');

        return room;
      } else {
        throw Exception('❌ Failed to create room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 [MatchService] Exception in createMatchRoom: $e');
      rethrow;
    }
  }

  /// 🔹 JOIN EXISTING ROOM (Custom)
  Future<MatchRoom> joinMatchRoom(String roomId) async {
    final uri = Uri.parse('$baseUrl/api/match/join');
    final payload = {'roomId': roomId};

    print('\n🔹 [MatchService] 🔹 JOIN MATCH ROOM');
    print('➡️ POST $uri');
    print('📦 Payload: $payload');

    try {
      final headers = await _getHeaders();
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final room = MatchRoom.fromJson(data);

        print('🎉 [MatchService] Room Joined: ${room.id}');
        socketService.emit('joinRoom', {'roomId': room.id});
        print('📡 [Socket] joinRoom emitted for ${room.id}');

        return room;
      } else {
        throw Exception('❌ Failed to join room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 [MatchService] Exception in joinMatchRoom: $e');
      rethrow;
    }
  }

  /// 🔹 FIND OR CREATE RANDOM MATCH ROOM
  Future<MatchRoom> findOrCreateRandomMatch({
    required String category,
    required String difficulty,
    required int amount,
  }) async {
    final uri = Uri.parse('$baseUrl/api/match/random');
    final payload = {
      'category': category,
      'difficulty': difficulty,
      'amount': amount,
    };

    print('\n🔹 [MatchService] 🔹 RANDOM MATCH');
    print('➡️ POST $uri');
    print('📦 Payload: $payload');

    try {
      final headers = await _getHeaders();
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final room = MatchRoom.fromJson(data);

        print('🎲 [MatchService] Matched to Room: ${room.id}');
        socketService.emit('joinRoom', {'roomId': room.id});
        print('📡 [Socket] joinRoom emitted for random room: ${room.id}');

        return room;
      } else {
        throw Exception('❌ Failed to find random match: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 [MatchService] Exception in findOrCreateRandomMatch: $e');
      rethrow;
    }
  }

  /// 🔹 START CUSTOM MATCH
  Future<void> startCustomMatch(String roomId) async {
    final uri = Uri.parse('$baseUrl/api/match/start');
    final payload = {'roomId': roomId};

    print('\n🔹 [MatchService] 🔹 START CUSTOM MATCH');
    print('➡️ POST $uri');
    print('📦 Payload: $payload');

    try {
      final headers = await _getHeaders();
      final response = await http.post(uri, headers: headers, body: jsonEncode(payload));

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('❌ Failed to start custom match: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 [MatchService] Exception in startCustomMatch: $e');
      rethrow;
    }
  }

  /// 🔹 SUBMIT FINAL ANSWERS
  Future<void> submitAnswer({
    required String roomId,
    required Map<String, String> answer,
    required int score,
  }) async {
    final uri = Uri.parse('$baseUrl/api/match/answer-bulk');
    final payload = {
      'roomId': roomId,
      'answers': answer,
      'score': score,
    };

    print('\n🔹 [MatchService] 🔹 SUBMIT FINAL ANSWERS');
    print('➡️ POST $uri');
    print('📦 Payload: ${jsonEncode(payload)}');

    try {
      final headers = await _getHeaders(); // Ensure this adds Auth + Content-Type
      headers['Content-Type'] = 'application/json';

      print('🧾 Headers: $headers');

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('❌ Failed to submit answers: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('🚨 [MatchService] Exception in submitAnswer: $e');
      print('📌 Stack Trace: $stackTrace');
      rethrow;
    }
  }


  /// 🔹 GET MATCH ROOM
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
        throw Exception('❌ Failed to fetch room: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 [MatchService] Exception in getMatchRoom: $e');
      rethrow;
    }
  }
  Future<Map<String, dynamic>> fetchMatchStatus(String roomId) async {
    final url = Uri.parse('$baseUrl/match/status/$roomId');
    print('📡 [MatchService] Fetching match status for room: $roomId');
    print('🌐 [MatchService] GET $url');

    try {
      final response = await http.get(url);
      print('📥 [MatchService] Response: ${response.statusCode}');
      print('📥 [MatchService] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [MatchService] Parsed match status: $data');
        return data;
      } else {
        print('❌ [MatchService] Failed with status ${response.statusCode}');
        throw Exception('Failed to fetch match status');
      }
    } catch (e) {
      print('🚨 [MatchService] Exception occurred: $e');
      rethrow;
    }
  }



  /// 🔹 GET LEADERBOARD
  Future<List<Map<String, dynamic>>> getLeaderboard(String roomId) async {
    final uri = Uri.parse('$baseUrl/api/leaderboard/$roomId');

    print('\n📊 [MatchService] 🔹 GET LEADERBOARD');
    print('➡️ GET $uri');

    try {
      final headers = await _getHeaders();
      print('🧾 Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (!data.containsKey('leaderboard')) {
          print('⚠️ No leaderboard field in response.');
          throw Exception('Invalid response format: leaderboard field missing');
        }

        final leaderboard = (data['leaderboard'] as List)
            .map((entry) => entry as Map<String, dynamic>)
            .toList();

        print('✅ Parsed Leaderboard:');
        for (var i = 0; i < leaderboard.length; i++) {
          print('  ${i + 1}. ${leaderboard[i]['name']} - ${leaderboard[i]['score']}');
        }

        return leaderboard;
      } else {
        throw Exception(
            '❌ Failed to fetch leaderboard: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('🚨 [MatchService] Exception in getLeaderboard: $e');
      print('🧵 StackTrace:\n$stackTrace');
      rethrow;
    }
  }


  /// 🔹 PRACTICE MODE - Fetch Questions from API
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

    print('\n🔹 [MatchService] 🔹 GENERATE PRACTICE QUESTIONS');
    print('➡️ GET $uri');

    try {
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      print('✅ Response Code: ${response.statusCode}');
      print('📝 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((q) => Question.fromJson(q)).toList();
      } else {
        throw Exception('❌ Failed to fetch questions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🚨 [MatchService] Exception in generatePracticeQuestions: $e');
      rethrow;
    }
  }
}
