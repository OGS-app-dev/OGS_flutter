// models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String date;
  final String time;
  final String location;
  final bool isLive;
  final String? siteUrl; 
  final String category; // New field to distinguish card types

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
    this.category = 'event', // Default to 'event'
  });

  // Factory constructor to create an Event from a Firestore DocumentSnapshot
  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
      [SnapshotOptions? options]) {
    final data = snapshot.data();
    return Event(
      id: snapshot.id,
      name: data?['name'] ?? 'Unknown Event',
      description: data?['description'] ?? 'No description provided.',
      imageUrl: data?['imageUrl'] ?? '',
      date: data?['date'] ?? 'N/A',
      time: data?['time'] ?? 'N/A',
      location: data?['location'] ?? 'N/A',
      isLive: data?['isLive'] ?? false,
      siteUrl: data?['siteUrl'],
      category: data?['category'] ?? 'event', // Default to 'event' if not specified
    );
  }

  // Convert Event to Firestore map
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
      "category": category,
    };
  }

  // Helper methods to check category
  bool get isEvent => category == 'event';
  bool get isUrl => category == 'url';
}