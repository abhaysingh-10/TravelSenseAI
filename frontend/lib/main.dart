import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  // ProviderScope is required at the root for Riverpod to work
  runApp(const ProviderScope(
    child: TravelSenseApp(),
  ));
}

class TravelSenseApp extends StatelessWidget {
  const TravelSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TravelSense AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}