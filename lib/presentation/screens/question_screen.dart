import 'package:flutter/material.dart';
import 'package:quiz/core/services/quiz_api.dart';
import 'quiz_screen.dart';

const List<String> categories = [
  'General Knowledge',
  'Science',
  'Mathematics',
  'History',
  'Geography',
  'Sports',
  'Politics',
  'Music',
  'Art',
  'Technology',
  'Books',
  'Movies',
  'Computer Science',
  'Nature',
];

class QuestionSetupScreen extends StatefulWidget {
  const QuestionSetupScreen({super.key});

  @override
  State<QuestionSetupScreen> createState() => _QuestionSetupScreenState();
}

class _QuestionSetupScreenState extends State<QuestionSetupScreen> {
  final QuizApi quizApi = QuizApi();

  String? selectedCategory = categories.first;
  String? selectedDifficulty = 'easy';
  int selectedAmount = 5;
  bool loading = false;

  final List<String> difficulties = ['easy', 'medium', 'hard'];

  void startQuiz() async {
    setState(() => loading = true);
    try {
      final questions = await quizApi.fetchQuestions(
        category: selectedCategory,
        difficulty: selectedDifficulty,
        amount: selectedAmount,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(questions: questions),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Category'),
              value: selectedCategory,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => selectedCategory = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Difficulty'),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : startQuiz,
              child: loading ? CircularProgressIndicator() : const Text('Start Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
