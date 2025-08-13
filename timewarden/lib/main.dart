import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'core/services/log_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/auth_wrapper.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  runApp(const TimeWardenApp());
}

class TimeWardenApp extends StatelessWidget {
  const TimeWardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(AuthRepositoryImpl(FirebaseService()))
            ..add(AuthCheckRequested()),
        ),
      ],
      child: MaterialApp(
        title: 'TimeWarden',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
