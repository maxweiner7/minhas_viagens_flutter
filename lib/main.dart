import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:minhas_viagens/SplashScreen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Demo',

      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

