import 'package:cloud_firestore/cloud_firestore.dart'; 

class Hospital {
  final String id; 
  final String name;
  final String location;
  final String imageUrl;
  final double? rating; 
  final String? siteUrl;

  Hospital({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    this.rating, 
    this.siteUrl,
  });

  factory Hospital.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data(); 

    if (data == null) {
      return Hospital(
        id: snapshot.id,
        name: 'Unavailable Hospital',
        location: 'Unknown',
        imageUrl: '', 
        rating: null,
                siteUrl:null,

      );
    }

    return Hospital(
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