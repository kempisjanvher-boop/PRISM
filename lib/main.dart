import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase/firebase_options.dart';
import 'onboarding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(PrismApp());
}

class PrismApp extends StatelessWidget {
  const PrismApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PRISM System',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto', // Clean modern font matching the image style
      ),
      home: PrismOnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}