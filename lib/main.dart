import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase_options.dart';
// ignore: unused_import
import 'package:ogs/pages/homepage.dart';

// ignore: unused_import
import 'package:ogs/pages/loginpage.dart';
// ignore: unused_import
import 'package:ogs/pages/signup_page.dart';
import 'package:ogs/services/landingservice/landingservice.dart';
import 'package:provider/provider.dart';

import 'form_response/form_response.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FormResponse>(
      create: (context) => FormResponse(),
      child:  MaterialApp(
        debugShowCheckedModeBanner: false,
        //home: Landing(),
        theme: ThemeData(
        fontFamily: 'Helvetica', 
        primarySwatch: Colors.blue,
      ),
        home:AnimatedSplashScreen(
          splash: "lib/assets/icons/ani.gif",
          nextScreen:const Landing(),
          duration: 3000,
          backgroundColor: yel,
          centered: true,
          splashIconSize: 200,
        )
      ),
    );
  }
}
