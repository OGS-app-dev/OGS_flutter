import 'package:cloud_firestore/cloud_firestore.dart'; 

class Restaurant {
  final String id; 
  final String name;
  final String location;
  final String imageUrl;
  final double? rating; 
  final String? siteUrl;

  Restaurant({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    this.rating, 
    this.siteUrl,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data(); 

    if (data == null) {
      return Restaurant(
        id: snapshot.id,
        name: 'Unavailable Restaurant',
        location: 'Unknown',
        imageUrl: '', 
        rating: null,
        siteUrl: null,

      );
    }

    return Restaurant(
      id: snapshot.id, 
      name: data['name'] ?? 'No Name',
      location: data['location'] ?? 'No Location Provided',
      imageUrl: data['imageUrl'] ?? 'assets/placeholder.png', 
      rating: (data['rating'] as num?)?.toDouble(), 
      siteUrl: data['siteUrl'],

    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "location": location,
      "imageUrl": imageUrl,
      "rating": rating,
    };
  }
}