import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/presentation/screens/quiz_screen.dart';

const List<String> categories = [
  'General Knowledge', 'Science', 'Mathematics', 'History', 'Geography',
  'Sports', 'Politics', 'Music', 'Art', 'Technology', 'Books',
  'Movies', 'Computer Science', 'Nature'
];

class QuestionSetupScreen extends StatefulWidget {
  final String mode; // 'practice', 'random', or 'custom'
  final String? customRoomId;

  const QuestionSetupScreen({
    super.key,
    required this.mode,
    this.customRoomId,
  });

  @override
  State<QuestionSetupScreen> createState() => _QuestionSetupScreenState();
}

class _QuestionSetupScreenState extends State<QuestionSetupScreen> {
  String? selectedCategory = categories.first;
  String? selectedDifficulty = 'easy';
  int selectedAmount = 5;
  bool loading = false;

  final List<String> difficulties = ['easy', 'medium', 'hard'];

  Future<void> startQuiz() async {
    setState(() => loading = true);

    final token = 'YOUR_AUTH_TOKEN_HERE'; // Replace with Firebase token

    try {
      if (widget.mode == 'practice') {
        final uri = Uri.parse(
            'https://opentdb.com/api.php?amount=$selectedAmount&category=9&difficulty=$selectedDifficulty&type=multiple');
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['response_code'] == 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(
                questions: data['results'],
                matchRoom: null,
              ),
            ),
          );
        } else {
          throw Exception("No questions found.");
        }
      } else if (widget.mode == 'random') {
        final uri = Uri.parse('https://quiz-backend-lnrb.onrender.com/api/match/create');
        final res = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'category': selectedCategory,
            'difficulty': selectedDifficulty,
            'questionCount': selectedAmount,
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 201 && data['roomId'] != null) {
          final matchRoom = MatchRoom(
            id: data['roomId'],
            category: selectedCategory!,
            difficulty: selectedDifficulty!,
            amount: selectedAmount,
            status: 'waiting',
            players: [],
            questions: [],
            createdAt: DateTime.now(),
            capacity: data['capacity'] ?? 2,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(
                questions: [],
                matchRoom: matchRoom,
              ),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Match room creation failed.');
        }
      } else if (widget.mode == 'custom' && widget.customRoomId != null) {
        final uri = Uri.parse('https://quiz-backend-lnrb.onrender.com/api/match/setupCustomRoom');
        final res = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'roomId': widget.customRoomId,
            'category': selectedCategory,
            'difficulty': selectedDifficulty,
            'questionCount': selectedAmount,
          }),
        );

        final data = jsonDecode(res.body);
        if (res.statusCode == 200 && data['success'] == true) {
          final matchRoom = MatchRoom(
            id: widget.customRoomId!,
            category: selectedCategory!,
            difficulty: selectedDifficulty!,
            amount: selectedAmount,
            status: 'waiting',
            players: [],
            questions: [],
            createdAt: DateTime.now(),
            capacity: data['capacity'] ?? 2,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuizScreen(
                questions: [],
                matchRoom: matchRoom,
              ),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Custom room setup failed.');
        }
      } else {
        throw Exception('Invalid mode or missing roomId.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.mode.toUpperCase()} Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Category'),
              value: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Difficulty'),
              value: selectedDifficulty,
              items: difficulties
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) => setState(() => selectedDifficulty = val),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Number of Questions'),
              keyboardType: TextInputType.number,
              initialValue: selectedAmount.toString(),
              onChanged: (val) {
                final parsed = int.tryParse(val);
                if (parsed != null && parsed > 0) {
                  setState(() => selectedAmount = parsed);
                }
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : startQuiz,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
