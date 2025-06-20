import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_unescape/html_unescape.dart';

import 'package:quiz/core/cubit/match_cubit.dart';
import 'package:quiz/core/cubit/match_state.dart';
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/data/models/question_model.dart';
import 'results_screen.dart';
import 'package:quiz/presentation/widgets/app_drawer.dart';
import 'package:go_router/go_router.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final MatchRoom? matchRoom;

  const QuizScreen({
    super.key,
    required this.questions,
    this.matchRoom,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  late Timer timer;
  int timeLeft = 0;
  Map<int, String> selectedAnswers = {};
  final unescape = HtmlUnescape();
  bool quizEnded = false;

  @override
  void initState() {
    super.initState();
    timeLeft = widget.questions.length * 12;
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (timeLeft == 0) {
        endQuiz();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  void endQuiz() {
    if (quizEnded) return;
    timer.cancel();
    setState(() => quizEnded = true);

    int score = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (selectedAnswers[i] == widget.questions[i].correctAnswer) {
        score++;
      }
    }

    if (widget.matchRoom != null) {
      final matchCubit = context.read<MatchCubit>();
      matchCubit.submitAnswers(widget.matchRoom!.id, selectedAnswers, score);
    }

    context.goNamed(
      'results',
      extra: {
        'score': score,
        'total': widget.questions.length,
        'questions': widget.questions,
        'selectedAnswers': selectedAnswers,
        'roomId': widget.matchRoom?.id,
      },
    );
  }

  void selectAnswer(String answer) {
    setState(() {
      if (selectedAnswers[currentIndex] == answer) {
        selectedAnswers.remove(currentIndex);
      } else {
        selectedAnswers[currentIndex] = answer;
      }
    });
  }


  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[currentIndex];
    final question = unescape.convert(q.question);
    final List<String> answers = q.allAnswers.map(unescape.convert).toList();

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: const Color(0xFF1E1E3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2C54),
        foregroundColor: Colors.white,
        title: Text('Question ${currentIndex + 1}/${widget.questions.length}'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('⏳ $timeLeft sec'),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // ✅ Styled answer options
            ...answers.map((answer) {
              final isSelected = selectedAnswers[currentIndex] == answer;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Material(
                  color: isSelected ? Colors.blueAccent : const Color(0xFF2C2C54),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => selectAnswer(answer),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Text(
                        answer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 30),

            // ✅ Styled navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentIndex > 0)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => currentIndex--),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A00E0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    label: const Text('Previous'),
                  ),
                if (currentIndex < widget.questions.length - 1)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => setState(() => currentIndex++),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8E2DE2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    label: const Text('Next'),
                  ),
              ],
            ),

            const Spacer(),

            // ✅ Submit button
            Center(
              child: ElevatedButton.icon(
                onPressed: endQuiz,
                icon: const Icon(Icons.flag),
                label: const Text('Submit Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
