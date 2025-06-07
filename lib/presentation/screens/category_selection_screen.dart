import 'package:flutter/material.dart';
import 'package:quiz/presentation/screens/matchmaking_screen.dart';
import 'package:quiz/core/cubit/match_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quiz/core/services/socket_service.dart';
import 'package:quiz/core/services/match_service.dart';
import 'package:quiz/core/services/quiz_api.dart';

class CategorySelectionScreen extends StatefulWidget {
  final String mode;
  const CategorySelectionScreen({super.key, required this.mode});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  String _selectedCategory = 'History';
  String _selectedDifficulty = 'easy';
  int _questionCount = 5;

  final List<String> categories = [
    'General Knowledge',  // capitalized properly as backend expects
    'Sports',
    'Science',
    'History',
    'Mathematics',
    'Geography',
    'Politics',
    'Music',
    'Art',
    'Technology',
    'Books',
    'Movies',
    'Computer Science',
    'Nature',
  ];
  final List<String> difficulties = ['easy', 'medium', 'hard'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Quiz Settings')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(labelText: 'Difficulty'),
              items: difficulties
                  .map((diff) => DropdownMenuItem(value: diff, child: Text(diff)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDifficulty = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _questionCount.toString(),
              decoration: const InputDecoration(labelText: 'Number of Questions'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                final num = int.tryParse(val);
                if (num != null && num > 0) {
                  setState(() => _questionCount = num);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => MatchCubit(
                        matchService: MatchService(),
                        socketService: SocketService(),
                          quizApi: QuizApi(),

                      ),
                      child: MatchMakingScreen(
                        category: _selectedCategory,
                        difficulty: _selectedDifficulty,
                        questionCount: _questionCount,
                        mode: widget.mode, // ✅ Pass mode here
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Start Matchmaking'),
            ),


          ],
        ),
      ),
    );
  }
}
