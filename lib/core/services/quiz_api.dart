import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizApi {
  static const String host = 'https://quiz-backend-lnrb.onrender.com';

  Future<List<dynamic>> fetchQuestions({
    String? category,
    String? difficulty,
    int amount = 10,
  }) async {
    final uri = Uri.parse('$host/api/quiz/questions').replace(queryParameters: {
      'amount': amount.toString(),
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
    });
    print('[QuizApi] Fetching questions from URL: $uri');

    final response = await http.get(uri);
    print('[QuizApi] Response body: ${response.body}');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch quiz questions ${response.statusCode}');
    }

  }

  Future<void> submitAnswer({
    required String roomId,
    required String userId,
    required int questionIndex,
    required String selectedAnswer,
  }) async {
    final uri = Uri.parse('$host/api/match/submit');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'roomId': roomId,
        'uid': userId,
        'questionIndex': questionIndex,
        'answer': selectedAnswer,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit answer');
    }
  }

  Future<List<dynamic>> getLeaderboard(String roomId) async {
    final uri = Uri.parse('$host/api/leaderboard/$roomId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch leaderboard');
    }
  }
}
