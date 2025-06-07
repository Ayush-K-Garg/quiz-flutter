import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_unescape/html_unescape.dart';

import 'package:quiz/core/cubit/match_cubit.dart';
import 'package:quiz/core/cubit/match_state.dart';
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/data/models/question_model.dart';
import 'results_screen.dart';

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          score: score,
          total: widget.questions.length,
          questions: widget.questions,
          selectedAnswers: selectedAnswers,
          roomId: widget.matchRoom?.id, // ✅ Correctly passing roomId
        ),
      ),
    );
  }

  void selectAnswer(String answer) {
    setState(() => selectedAnswers[currentIndex] = answer);
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
      appBar: AppBar(
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...answers.map((answer) {
              final isSelected = selectedAnswers[currentIndex] == answer;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.blueAccent : null,
                  ),
                  onPressed: () => selectAnswer(answer),
                  child: Text(answer),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentIndex > 0)
                  ElevatedButton(
                    onPressed: () => setState(() => currentIndex--),
                    child: const Text('Previous'),
                  ),
                if (currentIndex < widget.questions.length - 1)
                  ElevatedButton(
                    onPressed: () => setState(() => currentIndex++),
                    child: const Text('Next'),
                  ),
              ],
            ),
            const Spacer(),

            // Leaderboard (for multiplayer mode)
            if (widget.matchRoom != null) ...[
              const Divider(),
              const Text('🏆 Live Leaderboard:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              BlocBuilder<MatchCubit, MatchState>(
                builder: (context, state) {
                  if (state is MatchLoaded) {
                    final players = state.matchRoom.players;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: players.map((p) {
                        return Text('${p.username}: ${p.score}');
                      }).toList(),
                    );
                  }
                  return const SizedBox();
                },
              ),
              const SizedBox(height: 12),
            ],

            // Submit button
            Center(
              child: ElevatedButton.icon(
                onPressed: endQuiz,
                icon: const Icon(Icons.flag),
                label: const Text('Submit Quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
