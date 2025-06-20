// lib/presentation/screens/matchmaking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'package:quiz/core/cubit/match_cubit.dart';
import 'package:quiz/core/cubit/match_state.dart';
import 'package:quiz/core/services/socket_service.dart';
import 'package:quiz/core/services/match_service.dart';
import 'package:quiz/core/services/quiz_api.dart';

import 'package:quiz/data/models/question_model.dart';
import 'package:quiz/data/models/match_room_model.dart';

import 'package:quiz/presentation/widgets/app_drawer.dart';
import 'quiz_screen.dart';

class MatchMakingScreen extends StatefulWidget {
  final String mode; // 'practice', 'random', or 'custom'
  final String category;
  final String difficulty;
  final int questionCount;

  const MatchMakingScreen({
    Key? key,
    required this.mode,
    required this.category,
    required this.difficulty,
    required this.questionCount,
  }) : super(key: key);

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
      drawer: const CustomDrawer(),
      appBar: AppBar(title: const Text('Matchmaking')),
      body: BlocConsumer<MatchCubit, MatchState>(
        listener: (context, state) {
          if (state is MatchError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }

          if (state is MatchLoaded && state.matchRoom.status == 'started') {
            final matchRoom = state.matchRoom;

            List<Question> questions;

            // Defensive check: if questions are already Question objects, use directly
            if (matchRoom.questions.isNotEmpty &&
                matchRoom.questions.first is Question) {
              questions = List<Question>.from(matchRoom.questions);
            } else {
              questions = (matchRoom.questions as List<dynamic>)
                  .map((q) => Question.fromJson(q as Map<String, dynamic>))
                  .toList();
            }

            context.goNamed(
              'quiz',
              extra: {
                'questions': questions,
                'matchRoom': matchRoom,
              },
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
                        ? 'Waiting for opponent... (${room.players.length}/${room.capacity} joined)'
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
