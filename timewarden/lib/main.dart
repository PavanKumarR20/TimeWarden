import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'firebase_options_secure.dart';
import 'core/services/log_service.dart';
import 'core/services/theme_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/pomodoro_background_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/auth_wrapper.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/pomodoro/presentation/bloc/pomodoro_bloc.dart';
import 'features/habits/presentation/bloc/habits_bloc.dart';
import 'features/habits/data/repositories/habit_repository_impl.dart';
import 'features/journal/presentation/bloc/journal_bloc.dart';
import 'features/journal/data/repositories/journal_repository_impl.dart';
import 'features/journal/presentation/bloc/goal_bloc.dart';
import 'features/journal/data/repositories/goal_repository_impl.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (check if not already initialized)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LogService.firebase('Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      LogService.firebase('Firebase already initialized, continuing...');
    } else {
      LogService.firebase('Firebase initialization error', error: e);
      rethrow;
    }
  }

  // Test Firestore connection
  try {
    LogService.firebase('Testing Firestore connection...');
    await FirebaseFirestore.instance.enableNetwork();
    LogService.firebase('Firestore connection successful');
  } catch (e) {
    LogService.firebase('Firestore connection error', error: e);
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize background service
  await PomodoroBackgroundService.initialize();

  runApp(const TimeWardenApp());
}

class TimeWardenApp extends StatelessWidget {
  const TimeWardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) =>
                    AuthBloc(AuthRepositoryImpl(FirebaseService())),
              ),
              BlocProvider(
                create: (context) => PomodoroBloc(),
              ),
              BlocProvider(
                create: (context) => HabitsBloc(
                  HabitRepositoryImpl(FirebaseService()),
                ),
              ),
              BlocProvider(
                create: (context) => JournalBloc(
                  JournalRepositoryImpl(FirebaseService()),
                ),
              ),
              BlocProvider(
                create: (context) => GoalBloc(
                  GoalRepositoryImpl(FirebaseService()),
                ),
              ),
            ],
            child: MaterialApp(
              title: 'TimeWarden',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeService.themeMode,
              home: const AuthWrapper(),
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return AnimatedTheme(
                  duration: const Duration(milliseconds: 300),
                  data: Theme.of(context),
                  child: child!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
