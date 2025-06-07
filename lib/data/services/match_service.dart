import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/match_room_model.dart';

class MatchService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api/match';

  Future<MatchRoom> createMatchRoom(
      String category,
      String difficulty,
      int amount,
      String token,
      ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'category': category,
        'difficulty': difficulty,
        'questionCount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return MatchRoom.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create match room');
    }
  }

  Future<MatchRoom> joinMatchRoom(String roomId, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'roomId': roomId}),
    );

    if (response.statusCode == 200) {
      return MatchRoom.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to join match room');
    }
  }

  Future<List<dynamic>> getLeaderboard(String roomId) async {
    final response = await http.get(Uri.parse('$_baseUrl/leaderboard/$roomId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch leaderboard');
    }
  }
}
