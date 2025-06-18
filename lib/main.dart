import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quiz/core/cubit/match_cubit.dart';
import 'core/themes/theme_cubit.dart';
import 'core/themes/app_theme.dart';
import 'firebase_options.dart';
import 'state/auth_cubit.dart';
import 'routes/app_routes.dart';
import 'package:quiz/core/services/match_service.dart';
import 'package:quiz/core/services/socket_service.dart';
import 'package:quiz/core/services/quiz_api.dart';
// This should contain your GoRouter instance

Future<void> main() async {
  final quizapi=QuizApi();
  final socketService=SocketService();
  final match=MatchService();
  WidgetsFlutterBinding.ensureInitialized();
  socketService.connect(); // ✅ Connect socket before app runs

  // Initialize Firebase with generated options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase client with your project URL and anon key
  await Supabase.initialize(
    url: 'https://wrlosqabsqkscvkfpqhu.supabase.co',
    anonKey: '',
  );

  runApp(BlocProvider(
    create: (_) => MatchCubit(matchService: match, socketService: socketService, quizApi: quizapi),
    child: const MyApp(),
  ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AuthCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Thinksy',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            routerConfig: AppRoutes.router,
          );
        },
      ),
    );
  }
}
