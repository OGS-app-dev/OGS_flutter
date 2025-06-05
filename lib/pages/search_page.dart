import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase/dbservices.dart';
import 'package:ogs/models/event_model.dart';
import 'package:ogs/pages/event_details.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ogs/pages/fnu_restaurants.dart';
import 'package:ogs/pages/fnu_hotel.dart';
import 'package:ogs/pages/fnu_hospitals.dart';
import 'package:ogs/pages/fnu_movies.dart';
import 'package:ogs/pages/fnu_petrol.dart';

class SearchPage extends StatefulWidget {
  final String searchQuery;
  
  const SearchPage({
    super.key,
    required this.searchQuery,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FireDb _fireDb = FireDb();
  final TextEditingController _searchController = TextEditingController();
  String currentQuery = '';
  bool isSearching = false;
  
  // Only events search results
  List<DocumentSnapshot> eventResults = [];

  // Facility categories for navigation
  final List<Map<String, dynamic>> facilities = [
    {
      'name': 'Movies',
      'icon': CupertinoIcons.film,
      'color': Colors.red,
      'keywords': ['movies', 'cinema', 'theater', 'film', 'entertainment'],
      'page': () => const MoviesPage(),
    },
    {
      'name': 'Restaurants',
      'icon': CupertinoIcons.house,
      'color': Colors.orange,
      'keywords': ['restaurants', 'food', 'dining', 'eat', 'cafe', 'restaurant'],
      'page': () => const RestaurantsPage(),
    },
    {
      'name': 'Hotels',
      'icon': CupertinoIcons.bed_double,
      'color': Colors.blue,
      'keywords': ['hotels', 'accommodation', 'stay', 'lodge', 'guest house'],
      'page': () => const HotelPage(),
    },
    {
      'name': 'Hospitals',
      'icon': CupertinoIcons.plus_circled,
      'color': Colors.green,
      'keywords': ['hospitals', 'medical', 'health', 'clinic', 'doctor', 'emergency'],
      'page': () => const HospitalPage(),
    },
    {
      'name': 'Petrol Pumps',
      'icon': CupertinoIcons.car,
      'color': Colors.purple,
      'keywords': ['petrol', 'gas', 'fuel', 'pump', 'station'],
      'page': () => const PetrolPage(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    currentQuery = widget.searchQuery;
    if (currentQuery.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() async {
    setState(() {
      currentQuery = _searchController.text.trim();
      isSearching = true;
    });

    if (currentQuery.isEmpty) {
      setState(() {
        isSearching = false;
        eventResults.clear();
      });
      return;
    }

    try {
      // Search only in events collection for name field
      List<DocumentSnapshot> results = await _searchEventsCollection(currentQuery);
      
      setState(() {
        eventResults = results;
        isSearching = false;
      });

      // Save search query to user's history
      if (_fireDb.getCurrentUser() != null) {
        await _fireDb.saveSearchQuery(_fireDb.getCurrentUser()!.uid, currentQuery);
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        isSearching = false;
      });
    }
  }

  // Use the optimized FireDb search method
  Future<List<DocumentSnapshot>> _searchEventsCollection(String query) async {
    try {
      // Use the improved search method from FireDb
      return await _fireDb.searchEventsByName(query);
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _getMatchingFacilities() {
    if (currentQuery.isEmpty) return [];
    
    return facilities.where((facility) {
      List<String> keywords = List<String>.from(facility['keywords']);
      return keywords.any((keyword) =>
          keyword.toLowerCase().contains(currentQuery.toLowerCase()));
    }).toList();
  }

  Widget _buildEventCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: data['imageUrl'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['imageUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: yel.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(CupertinoIcons.calendar, color: yel, size: 24),
                  ),
                ),
              )
            : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: yel.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(CupertinoIcons.calendar, color: yel, size: 24),
              ),
        title: Text(
          data['name'] ?? 'Event',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['description'] != null)
              Text(
                data['description'],
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (data['date'] != null || data['eventDate'] != null) ...[
              const SizedBox(height: 4),
              Text(
                data['date'] ?? data['eventDate'],
                style: GoogleFonts.outfit(
                  color: yel,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(
          CupertinoIcons.chevron_right,
          color: pricol,
          size: 18,
        ),
        onTap: () {
          // Navigate to event details
          try {
            // Convert DocumentSnapshot to Event model
            Event event = Event.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
            
            // Navigate to EventDetailPage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailPage(event: event),
              ),
            );
          } catch (e) {
            print('Error navigating to event details: $e');
            // Show error message to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening event details'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: facility['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            facility['icon'],
            color: facility['color'],
            size: 24,
          ),
        ),
        title: Text(
          facility['name'],
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          'Explore ${facility['name'].toLowerCase()} near you',
          style: GoogleFonts.outfit(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          CupertinoIcons.chevron_right,
          color: pricol,
          size: 18,
        ),
        onTap: () {
          PersistentNavBarNavigator.pushNewScreen(
            context,
            screen: facility['page'](),
            withNavBar: false,
            pageTransitionAnimation: PageTransitionAnimation.cupertino,
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C2C2C),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: pricol.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: pricol,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> matchingFacilities = _getMatchingFacilities();
    bool hasResults = eventResults.isNotEmpty || matchingFacilities.isNotEmpty;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: pricol),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Results',
          style: GoogleFonts.outfit(
            color: const Color(0xFF2C2C2C),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Search events and facilities...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                prefixIcon: const Icon(CupertinoIcons.search, color: pricol),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            currentQuery = '';
                            eventResults.clear();
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.search, color: pricol),
                      onPressed: _performSearch,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: pricol, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.outfit(fontSize: 16),
            ),
          ),
          Expanded(
            child: isSearching
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: pricol),
                        SizedBox(height: 16),
                        Text('Searching events...'),
                      ],
                    ),
                  )
                : currentQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Search for events',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find events by name or browse facilities...',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : !hasResults
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_circle,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results found',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try different keywords or browse facilities',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Events Section
                                if (eventResults.isNotEmpty) ...[
                                  _buildSectionHeader('Events', eventResults.length),
                                  ...eventResults.map((doc) => _buildEventCard(doc)),
                                ],

                                // Facility Categories
                                if (matchingFacilities.isNotEmpty) ...[
                                  _buildSectionHeader('Facilities', matchingFacilities.length),
                                  ...matchingFacilities.map((facility) => _buildFacilityCard(facility)),
                                ],

                                const SizedBox(height: 80),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}