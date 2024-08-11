import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ogs/firebase_options.dart';
// ignore: unused_import
import 'package:ogs/pages/homepage.dart';

// ignore: unused_import
import 'package:ogs/pages/loginpage.dart';
// ignore: unused_import
import 'package:ogs/pages/signup_page.dart';
import 'package:ogs/services/landingservice/landingservice.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Landing(),
      //home: HomePage(location: 'Palakkad'),
    );
  }
}