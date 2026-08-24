import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return const MaterialApp(
      title: 'TravelSense AI',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Welcome to TravelSense AI!'),
        ),
      ),
    );
  }
}