import 'package:cloud_firestore/cloud_firestore.dart'; 

class Movie {
  final String id; 
  final String name;
  final String imageUrl;
  final double? rating; 
  final String? siteUrl;

  Movie({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.rating, 
    this.siteUrl,
  });

  factory Movie.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data(); 

    if (data == null) {
      return Movie(
        id: snapshot.id,
        name: 'Unavailable Movie',
        imageUrl: '', 
        rating: null,
                siteUrl:null,

      );
    }

    return Movie(
      id: snapshot.id, 
      name: data['name'] ?? 'No Name',
      imageUrl: data['imageUrl'] ?? 'assets/placeholder.png', 
      rating: (data['rating'] as num?)?.toDouble(), 
      siteUrl: data['siteUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "imageUrl": imageUrl,
      "rating": rating,
            "siteUrl": siteUrl,

    };
  }
}