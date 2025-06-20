import 'package:go_router/go_router.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/friends_screen.dart';
import 'package:quiz/presentation/screens/user_search_screen.dart';
import 'package:quiz/presentation/screens/question_screen.dart';
import 'package:quiz/presentation/screens/mode_selection_screen.dart';
import 'package:quiz/presentation/screens/profile_screen.dart';
import 'package:quiz/presentation/screens/about_screen.dart';
import 'package:quiz/presentation/screens/customroom_setup_screen.dart';
import 'package:quiz/presentation/screens/category_selection_screen.dart';
import 'package:quiz/presentation/screens/waiting_room_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quiz/presentation/screens/matchmaking_screen.dart';
import 'package:quiz/core/cubit/match_cubit.dart';
import 'package:quiz/core/services/match_service.dart';
import 'package:quiz/core/services/socket_service.dart';
import 'package:quiz/core/services/quiz_api.dart';
import 'package:quiz/presentation/screens/quiz_screen.dart';
import 'package:quiz/data/models/question_model.dart';
import 'package:quiz/data/models/match_room_model.dart';
import 'package:quiz/presentation/screens/results_screen.dart';
import 'package:quiz/presentation/screens/testscreen.dart';

class AppRoutes {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/mode-selection',
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) =>  FriendScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ModeSelectionScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/custom-room-setup',
        builder: (context, state) => const CustomRoomSetupScreen(),
      ),
      GoRoute(
        path: '/category',
        builder: (context, state) => const CategorySelectionScreen(mode: 'practice'),
      ),
      GoRoute(
        path: '/category/:mode',
        builder: (context, state) => CategorySelectionScreen(mode: state.pathParameters['mode']!),
      ),
      GoRoute(
        path: '/waiting-room/:roomId',
        name: 'waitingRoom',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final isHostStr = state.uri.queryParameters['isHost'] ?? 'false';
          final capacityStr = state.uri.queryParameters['capacity'] ?? '2';

          final isHost = isHostStr.toLowerCase() == 'true';
          final capacity = int.tryParse(capacityStr) ?? 2;

          return WaitingRoomScreen(
            roomId: roomId,
            isHost: isHost,
            capacity: capacity,
          );
        },
      ),
      GoRoute(
        path: '/matchmaking',
        name: 'matchmaking',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          final category = qp['category'] ?? 'General Knowledge';
          final difficulty = qp['difficulty'] ?? 'easy';
          final questionCount = int.tryParse(qp['questionCount'] ?? '5') ?? 5;
          final mode = qp['mode'] ?? 'practice';

          return BlocProvider(
            create: (_) => MatchCubit(
              matchService: MatchService(),
              socketService: SocketService(),
              quizApi: QuizApi(),
            ),
            child: MatchMakingScreen(
              category: category,
              difficulty: difficulty,
              questionCount: questionCount,
              mode: mode,
            ),
          );
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final matchRoom = extra['matchRoom'] as MatchRoom;
          final questions = extra['questions'] as List<Question>;

          return QuizScreen(
            questions: questions,
            matchRoom: matchRoom,
          );
        },
      ),
      GoRoute(
        name: 'results',
        path: '/results',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResultScreen(
            score: extra['score'] as int,
            total: extra['total'] as int,
            questions: extra['questions'] as List<Question>,
            selectedAnswers: extra['selectedAnswers'] as Map<int, String>,
            roomId: extra['roomId'] as String?,
          );
        },
      ),




    ],
  );
}
