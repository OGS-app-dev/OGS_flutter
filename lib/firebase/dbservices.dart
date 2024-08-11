import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FireDb {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetails(
      String uid) async {
    return await _firebase.collection('users').doc(uid).get();
  }

  Future<void> updateDoc(
      String collectionName, docID, Map<String, dynamic> data) async {
    try {
      await _firebase
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection(collectionName)
          .doc(docID)
          .update(data);
    } catch (e) {
      print(e.toString());
    }
  }
}
