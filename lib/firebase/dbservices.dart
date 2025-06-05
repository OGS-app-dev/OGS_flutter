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

  Future<List<DocumentSnapshot>> searchEventsByName(String query) async {
    if (query.isEmpty) return [];
    
    try {
      String lowerQuery = query.toLowerCase().trim();
      
      QuerySnapshot allEvents = await _firebase
          .collection('events')
          .get();

      List<DocumentSnapshot> filteredResults = [];
      
      for (var doc in allEvents.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String name = (data['name'] ?? '').toString().toLowerCase();
        
        // Check for partial matches, exact matches, and hyphen variations
        if (name.contains(lowerQuery) || 
            lowerQuery.contains(name) ||
            name.replaceAll('-', '').contains(lowerQuery.replaceAll('-', '')) ||
            name.replaceAll(' ', '').contains(lowerQuery.replaceAll(' ', ''))) {
          filteredResults.add(doc);
        }
      }

      filteredResults.sort((a, b) {
        String nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
        String nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
        
        if (nameA == lowerQuery && nameB != lowerQuery) return -1;
        if (nameB == lowerQuery && nameA != lowerQuery) return 1;
        
        if (nameA.startsWith(lowerQuery) && !nameB.startsWith(lowerQuery)) return -1;
        if (nameB.startsWith(lowerQuery) && !nameA.startsWith(lowerQuery)) return 1;
        
        return nameA.compareTo(nameB);
      });

      return filteredResults;
    } catch (e) {
      print('Error searching events by name: $e');
      return [];
    }
  }

  Future<List<DocumentSnapshot>> searchEventsByNameEfficient(String query) async {
    if (query.isEmpty) return [];
    
    try {
      String lowerQuery = query.toLowerCase().trim();
      List<DocumentSnapshot> allResults = [];
      
      List<String> queryVariations = [
        lowerQuery,
        lowerQuery.replaceAll('-', ''),
        lowerQuery.replaceAll(' ', ''),
        lowerQuery.replaceAll('-', ' '),
        lowerQuery.replaceAll(' ', '-'),
      ];
      
      Set<String> seenIds = {};
      
      for (String searchQuery in queryVariations) {
        if (searchQuery.isEmpty) continue;
        
        QuerySnapshot results = await _firebase
            .collection('events')
            .where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThanOrEqualTo: searchQuery + '\uf8ff')
            .get();
        
        for (var doc in results.docs) {
          if (!seenIds.contains(doc.id)) {
            seenIds.add(doc.id);
            allResults.add(doc);
          }
        }
      }
      
      QuerySnapshot originalResults = await _firebase
          .collection('events')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      
      for (var doc in originalResults.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          allResults.add(doc);
        }
      }

      return allResults;
    } catch (e) {
      print('Error in efficient search: $e');
      return [];
    }
  }

  // Get events stream (optimized with basic ordering)
  Stream<QuerySnapshot> getEventsStream() {
    return _firebase
        .collection('events')
        .orderBy('name') // Simple ordering by name
        .snapshots();
  }

  // Save search query to user's history
  Future<void> saveSearchQuery(String userId, String query) async {
    try {
      await _firebase
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Keep only last 20 searches to avoid storage bloat
      QuerySnapshot oldSearches = await _firebase
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .orderBy('timestamp', descending: true)
          .get();
      
      // Delete old searches
      for (var doc in oldSearches.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error saving search query: $e');
    }
  }

  // Get user's recent search history (limited to 10)
  Stream<QuerySnapshot> getUserSearchHistory(String userId) {
    return _firebase
        .collection('users')
        .doc(userId)
        .collection('searchHistory')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<List<String>> getRecentSearchQueries(String userId) async {
    try {
      QuerySnapshot snapshot = await _firebase
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      
      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['query'] as String)
          .toList();
    } catch (e) {
      print('Error getting recent search queries: $e');
      return [];
    }
  }

  // Clear user's search history
  Future<void> clearSearchHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firebase
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .get();
      
      WriteBatch batch = _firebase.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }

  // Get event details by ID (for when user taps on search result)
  Future<DocumentSnapshot?> getEventById(String eventId) async {
    try {
      return await _firebase.collection('events').doc(eventId).get();
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }

  // Get events by category (for filtering)
  Future<List<DocumentSnapshot>> getEventsByCategory(String category) async {
    try {
      QuerySnapshot snapshot = await _firebase
          .collection('events')
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();
      
      return snapshot.docs;
    } catch (e) {
      print('Error getting events by category: $e');
      return [];
    }
  }

  // Get featured or popular events (if you have such fields)
  Stream<QuerySnapshot> getFeaturedEventsStream() {
    return _firebase
        .collection('events')
        .where('featured', isEqualTo: true)
        .orderBy('name')
        .limit(10)
        .snapshots();
  }
  
}