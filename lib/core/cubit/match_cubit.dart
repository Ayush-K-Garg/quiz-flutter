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
  }) : super(MatchInitial());


  void _connectToSocket({
    required void Function() onConnected,
    required Map<String, Function(dynamic)> listeners,
  }) {
    print('🟢 [MatchCubit] Connecting socket with listeners...');
    socketService.connect(
      onConnected: onConnected,
      listeners: listeners,
    );
  }

  Future<void> createRoom({
    required String category,
    required String difficulty,
    required int amount,
    required String mode,
    String? hostUid, // for custom mode
  }) async {
    print('\n🛠 [MatchCubit] Creating room...');
    print('🎯 Mode: $mode | 📂 Category: $category | 🎚 Difficulty: $difficulty | 🔢 Amount: $amount');

    if (mode == 'practice') {
      print('🧪 [MatchCubit] Practice mode detected. Fetching from QuizApi...');
      try {
        final questionsRaw = await quizApi.fetchQuestions(
          category: category,
          difficulty: difficulty,
          amount: amount,
        );
        final questions = questionsRaw.map<Question>((q) => Question.fromJson(q)).toList();

        print('✅ [MatchCubit] Received ${questions.length} questions.');

        final practiceRoom = MatchRoom(
          id: 'practice-${DateTime.now().millisecondsSinceEpoch}',
          customRoomId: null,
          category: category,
          difficulty: difficulty,
          amount: amount,
          status: 'started',
          capacity: 1,
          hostUid: null,
          players: [],
          questions: questions.map((q) => q.toJson()).toList(),
          createdAt: DateTime.now(),
        );

        emit(MatchLoaded(practiceRoom));
      } catch (e) {
        print('❌ [MatchCubit] Error generating practice questions: $e');
        emit(MatchError('Failed to generate practice questions: $e'));
      }
      return;
    }

    emit(MatchLoading());

    if (mode == 'random_match') {
      final room = await matchService.createMatchRoom(
        category: category,
        difficulty: difficulty,
        amount: amount,
        mode: mode,
      );

      if (room != null) {
        print('✅ [MatchCubit] Room created: ID=${room.id}');
        emit(MatchLoaded(room));

        _connectToSocket(
          onConnected: () {
            socketService.emit('joinRoom', {'roomId': room.id});
            print('📤 [Socket] joinRoom emitted for room: ${room.id}');
          },
          listeners: {
            'matchRoomUpdated': (data) {
              print('📥 matchRoomUpdated: $data');
              try {
                final updatedRoom = MatchRoom.fromJson(data);
                emit(MatchLoaded(updatedRoom));
              } catch (e) {
                print('❌ [MatchCubit] Failed to parse matchRoomUpdated: $e');
                emit(MatchError('Failed to parse matchRoomUpdated: $e'));
              }
            },
            'error': (data) {
              print('🚨 [Socket] Error: $data');
              emit(MatchError(data.toString()));
            },
          },
        );
      } else {
        print('⚠️ [MatchCubit] Room creation returned null');
        emit(MatchError('Room creation returned null'));
      }
    }

    if (mode == 'custom_room') {
      print('🏗 [MatchCubit] Creating custom room...');
      _connectToSocket(
        onConnected: () {
          socketService.emit('createCustomRoom', {
            'host': hostUid,
            'category': category,
            'difficulty': difficulty,
          });
          print('📤 [Socket] createCustomRoom emitted');
        },
        listeners: {
          'customRoomCreated': (data) {
            print('📥 customRoomCreated: $data');
            try {
              final customRoom = MatchRoom.fromJson(data);
              emit(MatchLoaded(customRoom));
            } catch (e) {
              print('❌ [MatchCubit] Failed to parse customRoomCreated: $e');
              emit(MatchError('Invalid customRoomCreated data: $e'));
            }
          },
          'userJoined': (data) {
            print('👥 userJoined: $data');
            try {
              final updatedRoom = MatchRoom.fromJson(data);
              emit(MatchLoaded(updatedRoom));
            } catch (e) {
              print('❌ [MatchCubit] Failed to parse userJoined: $e');
              emit(MatchError('Invalid userJoined data: $e'));
            }
          },
          'matchRoomUpdated': (data) {
            print('📥 matchRoomUpdated: $data');
            try {
              final updatedRoom = MatchRoom.fromJson(data);
              emit(MatchLoaded(updatedRoom));
            } catch (e) {
              print('❌ [MatchCubit] Failed to parse matchRoomUpdated: $e');
              emit(MatchError('Failed to parse matchRoomUpdated: $e'));
            }
          },
          'error': (data) {
            print('🚨 [Socket] Error: $data');
            emit(MatchError(data.toString()));
          },
        },
      );
    }
  }

  Future<void> joinRoom(String roomId) async {
    print('\n👥 [MatchCubit] Joining room: $roomId');
    emit(MatchLoading());

    try {
      final room = await matchService.joinMatchRoom(roomId);
      print('✅ [MatchCubit] Joined room successfully: ID=${room.id}');
      emit(MatchLoaded(room));

      _connectToSocket(
        onConnected: () {
          socketService.emit('joinRoom', {'roomId': roomId});
          print('📤 [Socket] joinRoom emitted for room: $roomId');
        },
        listeners: {
          'matchRoomUpdated': (data) {
            print('📥 matchRoomUpdated: $data');
            try {
              final updatedRoom = MatchRoom.fromJson(data);
              emit(MatchLoaded(updatedRoom));
            } catch (e) {
              print('❌ [MatchCubit] Failed to parse matchRoomUpdated: $e');
              emit(MatchError('Failed to parse matchRoomUpdated: $e'));
            }
          },
          'error': (data) {
            print('🚨 [Socket] Error: $data');
            emit(MatchError(data.toString()));
          },
        },
      );
    } catch (e) {
      print('❌ [MatchCubit] Failed to join room: $e');
      emit(MatchError('Failed to join room: $e'));
    }
  }

  Future<void> submitAnswers(
      String roomId,
      Map<int, String> answers,
      int score,
      ) async {
    print('\n📨 [MatchCubit] Submitting answers...');
    print('🆔 Room ID: $roomId | 🧠 Score: $score');
    print('📝 Answers: $answers');

    try {
      final stringifiedAnswers = answers.map((key, value) => MapEntry(key.toString(), value));

      await matchService.submitAnswer(
        roomId: roomId,
        answer: stringifiedAnswers,
        score: score,
      );

      print('✅ [MatchCubit] Answers submitted successfully.');
      emit(MatchSubmitted());
    } catch (e) {
      print('❌ [MatchCubit] Failed to submit answers: $e');
      emit(MatchError('Failed to submit answers: $e'));
    }
  }

  @override
  Future<void> close() {
    print('❎ [MatchCubit] Closing cubit and disconnecting socket.');
    socketService.disconnect();
    return super.close();
  }
}
