// lib/presentation/screens/matchmaking_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:quiz/core/cubit/match_cubit.dart';
import 'package:quiz/core/cubit/match_state.dart';
import 'package:quiz/data/models/question_model.dart'; // Your Question model
import 'quiz_screen.dart';

class MatchMakingScreen extends StatefulWidget {
  final String mode; // 'practice', 'random', or 'custom'
  final String category;
  final String difficulty;
  final int questionCount;

  const MatchMakingScreen({
    super.key,
    required this.mode,
    required this.category,
    required this.difficulty,
    required this.questionCount,
  });

  @override
  State<MatchMakingScreen> createState() => _MatchMakingScreenState();
}

class _MatchMakingScreenState extends State<MatchMakingScreen> {
  late String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    initiateMatch();
  }

  void initiateMatch() {
    final matchCubit = context.read<MatchCubit>();
    matchCubit.createRoom(
      category: widget.category,
      difficulty: widget.difficulty,
      amount: widget.questionCount,
      mode: widget.mode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matchmaking')),
      body: BlocConsumer<MatchCubit, MatchState>(
        listener: (context, state) {
          if (state is MatchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }

          if (state is MatchLoaded && state.matchRoom.status == 'started') {
            List<Question> questions;

            // Defensive check: if questions are already Question objects, use directly
            if (state.matchRoom.questions.isNotEmpty &&
                state.matchRoom.questions.first is Question) {
              questions = List<Question>.from(state.matchRoom.questions);
            } else {
              // Otherwise, parse from JSON maps
              questions = (state.matchRoom.questions as List<dynamic>)
                  .map((q) => Question.fromJson(q as Map<String, dynamic>))
                  .toList();
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => QuizScreen(
                  questions: questions,
                  matchRoom: state.matchRoom,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MatchLoading || state is MatchInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MatchLoaded) {
            final room = state.matchRoom;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Room ID: ${room.id}', style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 20),
                  Text(
                    room.status == 'waiting'
                        ? 'Waiting for opponent... (${room.players.length}/2 joined)'
                        : 'Match Starting...',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Unknown state'));
          }
        },
      ),
    );
  }
}
