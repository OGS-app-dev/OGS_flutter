import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ogs/pages/loginpage.dart';

class Mydrawer extends StatelessWidget {
  const Mydrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(child: Icon(Icons.travel_explore)),
          const ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          const ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          const ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false);
              }
            },
            child: const ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
