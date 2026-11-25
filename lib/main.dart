// lib/main.dart

import 'package:flutter/material.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/pages/auth_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  
  await Supabase.initialize(
    url: 'https://nuewfztbkkecjgnoavdh.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51ZXdmenRia2tlY2pnbm9hdmRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUzOTI2NDcsImV4cCI6MjEwMDk2ODY0N30.O2tzZl-Z8gEFD42eFqSOB1wWiU4Q22qT4MxlHX2ulKs',
  );

  await di.initDependencies();
  runApp(const InstagramCloneApp());
}

 

class InstagramCloneApp extends StatelessWidget {
  const InstagramCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Direct',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white, // Pure white Instagram backdrop
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.black, // Dark typography/icons
          secondary: Colors.blueAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}