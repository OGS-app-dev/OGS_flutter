import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HotelsDbService {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> hospitalCollections = [
    'hotels_calicut',
    'hotels_kattangal',
  ];

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<List<DocumentSnapshot>> searchhotelsByName(String query) async {
    if (query.isEmpty) return [];
    
    try {
      String lowerQuery = query.toLowerCase().trim();
      List<DocumentSnapshot> allResults = [];
      
      for (String collection in hospitalCollections) {
        QuerySnapshot collectionResults = await _firebase
            .collection(collection)
            .get();

        List<DocumentSnapshot> filteredResults = [];
        
        for (var doc in collectionResults.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? '').toString().toLowerCase();
          String location = (data['location'] ?? '').toString().toLowerCase();
          
          if (name.contains(lowerQuery) || 
              lowerQuery.contains(name) ||
              location.contains(lowerQuery) ||
              name.replaceAll('-', '').contains(lowerQuery.replaceAll('-', '')) ||
              name.replaceAll(' ', '').contains(lowerQuery.replaceAll(' ', '')) ||
              location.replaceAll(' ', '').contains(lowerQuery.replaceAll(' ', ''))) {
            DocumentSnapshot modifiedDoc = _addCollectionInfo(doc, collection);
            filteredResults.add(modifiedDoc);
          }
        }

        filteredResults.sort((a, b) {
          String nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
          String nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString().toLowerCase();
          
          // Exact matches first
          if (nameA == lowerQuery && nameB != lowerQuery) return -1;
          if (nameB == lowerQuery && nameA != lowerQuery) return 1;
          
          // Then starts with matches
          if (nameA.startsWith(lowerQuery) && !nameB.startsWith(lowerQuery)) return -1;
          if (nameB.startsWith(lowerQuery) && !nameA.startsWith(lowerQuery)) return 1;
          
          // Then alphabetical
          return nameA.compareTo(nameB);
        });

        allResults.addAll(filteredResults);
      }

      return allResults;
    } catch (e) {
      print('Error searching hotels by name: $e');
      return [];
    }
  }

  // Helper method to add collection information to document
  DocumentSnapshot _addCollectionInfo(DocumentSnapshot doc, String collection) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['_collection'] = collection;
    data['_area'] = _getAreaFromCollection(collection);
    
    // Create a new document snapshot with modified data
    return _createModifiedDocumentSnapshot(doc, data);
  }

  String _getAreaFromCollection(String collection) {
    switch (collection) {
      case 'hotels_calicut':
        return 'Calicut';
      case 'hotels_kattangal':
        return 'Kattangal';
      default:
        return 'Unknown Area';
    }
  }

  DocumentSnapshot _createModifiedDocumentSnapshot(DocumentSnapshot original, Map<String, dynamic> newData) {
   
    return original;
  }

  Future<List<DocumentSnapshot>> gethotelsByCollection(String collection) async {
    try {
      QuerySnapshot snapshot = await _firebase
          .collection(collection)
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) => _addCollectionInfo(doc, collection)).toList();
    } catch (e) {
      print('Error getting hotels from $collection: $e');
      return [];
    }
  }

  Future<List<DocumentSnapshot>> getAllhotels() async {
    List<DocumentSnapshot> allhotels = [];
    
    for (String collection in hospitalCollections) {
      List<DocumentSnapshot> hotels = await gethotelsByCollection(collection);
      allhotels.addAll(hotels);
    }
    
    allhotels.sort((a, b) {
      String nameA = ((a.data() as Map<String, dynamic>)['name'] ?? '').toString();
      String nameB = ((b.data() as Map<String, dynamic>)['name'] ?? '').toString();
      return nameA.compareTo(nameB);
    });
    
    return allhotels;
  }

  Stream<QuerySnapshot> gethotelsStream(String collection) {
    return _firebase
        .collection(collection)
        .orderBy('name')
        .snapshots();
  }

  Future<DocumentSnapshot?> getHospitalById(String hospitalId, String collection) async {
    try {
      DocumentSnapshot doc = await _firebase
          .collection(collection)
          .doc(hospitalId)
          .get();
      
      if (doc.exists) {
        return _addCollectionInfo(doc, collection);
      }
      return null;
    } catch (e) {
      print('Error getting hospital by ID: $e');
      return null;
    }
  }

  Future<void> savehotelsearchQuery(String userId, String query) async {
    try {
      await _firebase
          .collection('users')
          .doc(userId)
          .collection('hotelsearchHistory')
          .add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      QuerySnapshot oldSearches = await _firebase
          .collection('users')
          .doc(userId)
          .collection('hotelsearchHistory')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      
      if (oldSearches.docs.length > 20) {
        List<DocumentSnapshot> toDelete = oldSearches.docs.skip(20).toList();
        WriteBatch batch = _firebase.batch();
        for (var doc in toDelete) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error saving hospital search query: $e');
    }
  }

  Future<List<String>> getRecenthotelsearchQueries(String userId) async {
    try {
      QuerySnapshot snapshot = await _firebase
          .collection('users')
          .doc(userId)
          .collection('hotelsearchHistory')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      
      return snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['query'] as String)
          .toList();
    } catch (e) {
      print('Error getting recent hospital search queries: $e');
      return [];
    }
  }

  Future<void> clearhotelsearchHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firebase
          .collection('users')
          .doc(userId)
          .collection('hotelsearchHistory')
          .get();
      
      WriteBatch batch = _firebase.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error clearing hospital search history: $e');
    }
  }

  Future<List<DocumentSnapshot>> gethotelsByArea(String area) async {
    String collection = '';
    switch (area.toLowerCase()) {
      case 'calicut':
        collection = 'hotels_calicut';
        break;
      case 'kattangal':
        collection = 'hotels_kattangal';
        break;
      default:
        return [];
    }
    
    return await gethotelsByCollection(collection);
  }

  List<String> getAvailableAreas() {
    return hospitalCollections.map((collection) => _getAreaFromCollection(collection)).toList();
  }
}