import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/welcome.dart';
import 'services/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseOptions);
  await AppState.instance.load();
  runApp(const IpeobomApp());
}

class IpeobomApp extends StatelessWidget {
  const IpeobomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '입어봄',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const WelcomeScreen(),
    );
  }
}
