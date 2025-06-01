import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizApi {
  static const String host = 'http://10.0.2.2:3000'; // or your deployed URL

  Future<List<dynamic>> fetchQuestions({
    String? category,
    String? difficulty,
    int amount = 10,
  }) async {
    final uri = Uri.parse('$host/api/quiz/questions')
        .replace(queryParameters: {
      'amount': amount.toString(),
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch quiz questions');
    }
  }
}
