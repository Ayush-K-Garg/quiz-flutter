import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quiz/core/services/match_service.dart';
import 'package:quiz/core/services/socket_service.dart';
import 'package:quiz/core/services/quiz_api.dart';
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/data/models/question_model.dart';
import 'match_state.dart';

class MatchCubit extends Cubit<MatchState> {
  final MatchService matchService;
  final SocketService socketService;
  final QuizApi quizApi;

  MatchCubit({
    required this.matchService,
    required this.socketService,
    required this.quizApi,
  }) : super(MatchInitial()) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    print('[MatchCubit] Connecting socket...');
    socketService.connect();

    socketService.on('connect', (_) {
      print('[Socket] Connected to server.');
    });

    socketService.on('disconnect', (_) {
      print('[Socket] Disconnected from server.');
    });

    socketService.on('matchRoomUpdated', (data) {
      print('[Socket] matchRoomUpdated event received: $data');
      try {
        final updatedRoom = MatchRoom.fromJson(data);
        print('[MatchCubit] Parsed updated room: ${updatedRoom.id}');
        emit(MatchLoaded(updatedRoom));
      } catch (e) {
        print('[MatchCubit] Failed to parse matchRoomUpdated: $e');
        emit(MatchError('Failed to parse match room update: $e'));
      }
    });

    socketService.on('error', (data) {
      print('[Socket] Error event received: $data');
      emit(MatchError(data.toString()));
    });
  }

  Future<void> createRoom({
    required String category,
    required String difficulty,
    required int amount,
    required String mode,
  }) async {
    print('[MatchCubit] Mode: $mode | Category: $category | Difficulty: $difficulty | Amount: $amount');

    if (mode == 'practice') {
      print('[MatchCubit] Practice mode detected. Fetching practice questions from QuizApi.');

      try {
        final questionsRaw = await quizApi.fetchQuestions(
          category: category,
          difficulty: difficulty,
          amount: amount,
        );

        // Parse questions to your Question model
        final questions = questionsRaw.map<Question>((q) => Question.fromJson(q)).toList();

        print('[MatchCubit] Fetched ${questions.length} practice questions.');

        final practiceRoom = MatchRoom(
          id: 'practice-${DateTime.now().millisecondsSinceEpoch}',
          category: category,
          difficulty: difficulty,
          amount: amount,
          status: 'started',
          players: [],
          questions: questions,
          createdAt: DateTime.now(),
        );

        emit(MatchLoaded(practiceRoom));
      } catch (e) {
        print('[MatchCubit] Error generating practice questions: $e');
        emit(MatchError('Failed to generate practice questions: $e'));
      }

      return;
    }

    emit(MatchLoading());

    try {
      final room = await matchService.createMatchRoom(
        category: category,
        difficulty: difficulty,
        amount: amount,
        mode: mode,
      );

      if (room != null) {
        print('[MatchCubit] Room created successfully: ${room.id}');
        emit(MatchLoaded(room));
        socketService.emit('joinRoom', {'roomId': room.id});
      } else {
        print('[MatchCubit] Room creation returned null');
        emit(MatchError('Room creation returned null'));
      }
    } catch (e) {
      print('[MatchCubit] Error while creating room: $e');
      emit(MatchError('Failed to create room: $e'));
    }
  }

  Future<void> joinRoom(String roomId) async {
    print('[MatchCubit] Attempting to join room: $roomId');
    emit(MatchLoading());

    try {
      final room = await matchService.joinMatchRoom(roomId);
      print('[MatchCubit] Joined room successfully: ${room.id}');
      emit(MatchLoaded(room));
      socketService.emit('joinRoom', {'roomId': roomId});
    } catch (e) {
      print('[MatchCubit] Failed to join room: $e');
      emit(MatchError('Failed to join room: $e'));
    }
  }

  Future<void> submitAnswers(
      String roomId,
      Map<int, String> answers,
      int score,
      ) async {
    try {
      print('[MatchCubit] Submitting answers for room: $roomId with score: $score');
      final stringifiedAnswers = answers.map((key, value) => MapEntry(key.toString(), value));

      await matchService.submitAnswers(
        roomId: roomId,
        answers: stringifiedAnswers,
        score: score,
      );

      print('[MatchCubit] Answers submitted successfully.');
    } catch (e) {
      print('[MatchCubit] Failed to submit answers: $e');
      emit(MatchError('Failed to submit answers: $e'));
    }
  }

  @override
  Future<void> close() {
    print('[MatchCubit] Closing and disconnecting socket.');
    socketService.disconnect();
    return super.close();
  }
}
