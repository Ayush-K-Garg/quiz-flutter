import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz/core/cubit/match_cubit.dart';
import 'package:quiz/core/services/socket_service.dart';
import 'package:quiz/core/services/match_service.dart';
import 'package:quiz/core/services/quiz_api.dart';
import 'package:quiz/presentation/screens/matchmaking_screen.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';

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
    'General Knowledge',
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
      backgroundColor: const Color(0xFF1E1E3F),
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('Select Quiz Settings'),
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              'Choose your preferences:',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            /// Category dropdown
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF2C2C54),
              value: _selectedCategory,
              decoration: _inputDecoration('Category'),
              items: categories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat, style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),

            /// Difficulty dropdown
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF2C2C54),
              value: _selectedDifficulty,
              decoration: _inputDecoration('Difficulty'),
              items: difficulties
                  .map((diff) => DropdownMenuItem(
                value: diff,
                child: Text(diff, style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedDifficulty = value);
              },
            ),
            const SizedBox(height: 16),

            /// Question count
            TextFormField(
              initialValue: _questionCount.toString(),
              decoration: _inputDecoration('Number of Questions'),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                final num = int.tryParse(val);
                if (num != null && num > 0) {
                  setState(() => _questionCount = num);
                }
              },
            ),
            const SizedBox(height: 32),

            /// Start Matchmaking button
            InkWell(
              onTap: () {
                context.goNamed(
                  'matchmaking',
                  queryParameters: {
                    'category': _selectedCategory,
                    'difficulty': _selectedDifficulty,
                    'questionCount': _questionCount.toString(),
                    'mode': widget.mode,
                  },
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Start Match',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white38),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
