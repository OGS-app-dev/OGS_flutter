import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/form_response/form_response.dart';
import 'package:ogs/pages/bottomnavpage.dart';
import 'package:ogs/pages/signup_page.dart';
import 'package:ogs/widgets/mytextfield.dart';
import 'package:provider/provider.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passcontroller = TextEditingController();

  FormResponse? formResponse;

  void onTap() {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SignUpPage(),
        ));
  }


  void login() async {
    showDialog(
        context: context,
        builder: (context) => const SpinKitThreeBounce(
              color: Colors.black,
              size: 30,
            ));
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailcontroller.text,
        password: passcontroller.text,
      );
      if (mounted) {
        Navigator.pop(context);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get()
            .then((value) {
          formResponse?.role = value['role'];
        });

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainPage(),
            ));
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.code),
        ),
      );
    }
  }
  @override
  void initState() {
    formResponse = Provider.of<FormResponse>(context, listen: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pricol,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              
              const SizedBox(
                height: 280,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17.0, vertical: 8),
                child: MyTextField(
                  controller: emailcontroller,
                  title: 'email',
                  colo: bgcol,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17.0, vertical: 8),
                child: MyTextField(
                  controller: passcontroller,
                  title: 'password',
                  obsctext: true,
                  colo: bgcol,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 17.0, vertical: 8),
                child: GestureDetector(
                  onTap: login,
                  child: Material(
                    elevation: 4,
                    shadowColor: bgcol,
                    borderRadius: BorderRadius.circular(15),
                    color: tercol,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      child: Center(
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.poppins(
                              color: pricol,
                              fontSize: 20,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: const Text("Dont have an account? Sign Up Here",style: TextStyle(
                  color: bgcol
                ),),
              )
            ],
          ),
        ),
      ),
    );
  }
}
