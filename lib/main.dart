import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TokenGeneratorApp());
}

class TokenGeneratorApp extends StatelessWidget {
  const TokenGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Token Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
