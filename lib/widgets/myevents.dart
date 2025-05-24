import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/models/event_model.dart';
import 'package:ogs/pages/upcoming_events.dart';

class EventsHorizontalScrollView extends StatelessWidget {
  const EventsHorizontalScrollView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events found.'));
        }

        final events = snapshot.data!.docs;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: events.map((DocumentSnapshot document) {
              final event = Event.fromFirestore(
                  document as DocumentSnapshot<Map<String, dynamic>>);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailPage(event: event),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color.fromARGB(255, 245, 245, 245),
                      ),
                      height: 250,
                      width: 299,
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.black, // Placeholder background
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: event.imageUrl.startsWith('http')
                                    ? Image.network(
                                        event.imageUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                              color: Colors.yellow,
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    size: 50,
                                                    color: Colors.grey),
                                      )
                                    : Image.asset(
                                        event.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.error,
                                                    size: 50,
                                                    color: Colors.red),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            event.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color.fromARGB(255, 41, 41, 49),
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: const Color.fromARGB(255, 137, 137, 137),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (event.isLive)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Live',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 30,
                      bottom: 28,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: ShapeDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(0.52, -0.85),
                            end: Alignment(-0.52, 0.85),
                            colors: [Color(0xFFFFCC00), Color(0xFFFFE47C)],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0xAAFFE47C),
                              blurRadius: 13,
                              offset: Offset(-4, 5),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.play_arrow,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
