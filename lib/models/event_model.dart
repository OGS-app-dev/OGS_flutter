// models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class Event {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String date;
  final String time;
  final String location;
  final bool isLive;
  final String? siteUrl; // Make it nullable as discussed

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.time,
    required this.location,
    this.isLive = false,
    this.siteUrl,
  });

  // Factory constructor to create an Event from a Firestore DocumentSnapshot
  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data();
    return Event(
      id: snapshot.id, // Use snapshot.id for the document ID
      name: data?['name'] ?? 'Unknown Event',
      description: data?['description'] ?? 'No description provided.',
      imageUrl: data?['imageUrl'] ?? '',
      date: data?['date'] ?? 'N/A',
      time: data?['time'] ?? 'N/A',
      location: data?['location'] ?? 'N/A',
      isLive: data?['isLive'] ?? false,
      siteUrl: data?['siteUrl'], // siteUrl is nullable
    );
  }

  // You might still keep fromMap if you parse from generic Maps elsewhere,
  // but fromFirestore is specifically for Firestore DocumentSnapshots.
  // factory Event.fromMap(Map<String, dynamic> data) {
  //   return Event(
  //     id: data['id'] ?? '', // This would assume 'id' is in the map
  //     name: data['name'] ?? 'Unknown Event',
  //     description: data['description'] ?? 'No description provided.',
  //     imageUrl: data['imageUrl'] ?? '',
  //     date: data['date'] ?? 'N/A',
  //     time: data['time'] ?? 'N/A',
  //     location: data['location'] ?? 'N/A',
  //     isLive: data['isLive'] ?? false,
  //     siteUrl: data['siteUrl'],
  //   );
  // }

  // Optional: toFirestore method if you want to save Event objects to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "description": description,
      "imageUrl": imageUrl,
      "date": date,
      "time": time,
      "location": location,
      "isLive": isLive,
      "siteUrl": siteUrl,
    };
  }
}