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
// Add this extension to your existing FireDb class or create a new file
// This extends your existing FireDb service with search functionality


extension SearchExtension on FireDb {
  // Get events stream for search
  Stream<QuerySnapshot> getEventsStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Search events by query
  Future<List<DocumentSnapshot>> searchEvents(String query) async {
    if (query.isEmpty) return [];
    
    try {
      // Search in title field
      QuerySnapshot titleResults = await FirebaseFirestore.instance
          .collection('events')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Search in category field
      QuerySnapshot categoryResults = await FirebaseFirestore.instance
          .collection('events')
          .where('category', isGreaterThanOrEqualTo: query)
          .where('category', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Combine results and remove duplicates
      Set<String> seenIds = {};
      List<DocumentSnapshot> allResults = [];
      
      for (var doc in titleResults.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          allResults.add(doc);
        }
      }
      
      for (var doc in categoryResults.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          allResults.add(doc);
        }
      }

      return allResults;
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  // Search facilities (if you have them in Firestore)
  Future<List<DocumentSnapshot>> searchFacilities(String query) async {
    if (query.isEmpty) return [];
    
    try {
      QuerySnapshot results = await FirebaseFirestore.instance
          .collection('facilities')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return results.docs;
    } catch (e) {
      print('Error searching facilities: $e');
      return [];
    }
  }

  // Get recent searches (optional - to store user search history)
  Future<void> saveSearchQuery(String userId, String query) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving search query: $e');
    }
  }

  // Get user's search history
  Stream<QuerySnapshot> getUserSearchHistory(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('searchHistory')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }
}