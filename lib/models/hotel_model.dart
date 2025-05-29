import 'package:cloud_firestore/cloud_firestore.dart'; 

class Hotel {
  final String id; 
  final String name;
  final String location;
  final String imageUrl;
  final double? rating; 
    final String? siteUrl;


  Hotel({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    this.rating, 
        this.siteUrl,

  });

  factory Hotel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data(); 

    if (data == null) {
      return Hotel(
        id: snapshot.id,
        name: 'Unavailable Hotel',
        location: 'Unknown',
        imageUrl: '', 
        rating: null,
        siteUrl: null,
      );
    }

    return Hotel(
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
       "siteUrl": siteUrl,
    };
  }
}