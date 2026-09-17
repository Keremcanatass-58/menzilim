import 'package:flutter/material.dart';

import 'features/auth/screens/login_screen.dart';

void main() {
  runApp(const MenzilimApp());
}

class MenzilimApp extends StatelessWidget {
  const MenzilimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MENZİLİM',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}