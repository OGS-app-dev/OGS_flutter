// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ogs/pages/loginpage.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../form_response/form_response.dart';

class MainLoadingScreen extends StatefulWidget {
  static const String id = "MainLoadingScreen";
  const MainLoadingScreen({super.key});

  @override
  State<MainLoadingScreen> createState() => _MainLoadingScreenState();
}

class _MainLoadingScreenState extends State<MainLoadingScreen> {
  // final firebaseApi = FirebaseApi();
  SharedPreferences? _prefs;
  late final FormResponse formResponse;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _cloud = FirebaseFirestore.instance;
  String role = "";
  String busNo = "";
  Future<void> getPref() async {
    _prefs = await SharedPreferences.getInstance();
    formResponse.addSharedPref(_prefs!);
      //add the loginstate and username in memory cache
      //to autologin when opening up the app

      // String? userName = _auth.currentUser?.displayName;
      // context.mounted ? Provider.of<FormResponse>(context,listen: false).role = role : null;
      // context.mounted ? Provider.of<FormResponse>(context,listen: false).email = email : null;
      // context.mounted ? Provider.of<FormResponse>(context,listen: false).userName = userName! : null;
    Navigator.push(context,
    MaterialPageRoute(builder: (context) => const LoginPage()),
    );


  }
  String email = "";
  String pass = "";
  @override
  void initState() {
    // firebaseApi.configurePushNotifications(context);
    // firebaseApi.eventListenerCallback(context);
    formResponse = (context.mounted
        ? Provider.of<FormResponse>(context, listen: false)
        : null)!;
    getPref();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              // Image(
              //   width: 150,
              //   height: 150,
              //   image: AssetImage("assets/images/schoolBus.png"),
              // ),
              SizedBox(
                height: 10,
              ),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  color: Colors.pinkAccent,
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "V 1.3.3",
                    style: TextStyle(
                      color: Colors.black26,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
