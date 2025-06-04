import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase/dbservices.dart';
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

  // Facility categories
  final List<Map<String, dynamic>> facilities = [
    {
      'name': 'Movies',
      'icon': 'lib/assets/icons/movies.png',
      'keywords': ['movies', 'cinema', 'theater', 'film', 'entertainment'],
      'page': () => const MoviesPage(),
    },
    {
      'name': 'Restaurants',
      'icon': 'lib/assets/icons/res.png',
      'keywords': ['restaurants', 'food', 'dining', 'eat', 'cafe', 'restaurant'],
      'page': () => const RestaurantsPage(),
    },
    {
      'name': 'Hotels',
      'icon': 'lib/assets/icons/hotel.png',
      'keywords': ['hotels', 'accommodation', 'stay', 'lodge', 'guest house'],
      'page': () => const HotelPage(),
    },
    {
      'name': 'Hospitals',
      'icon': 'lib/assets/icons/hospital.png',
      'keywords': ['hospitals', 'medical', 'health', 'clinic', 'doctor', 'emergency'],
      'page': () => const HospitalPage(),
    },
    {
      'name': 'Petrol Pumps',
      'icon': 'lib/assets/icons/petrol.png',
      'keywords': ['petrol', 'gas', 'fuel', 'pump', 'station'],
      'page': () => const PetrolPage(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    currentQuery = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      currentQuery = _searchController.text.trim();
      isSearching = true;
    });
    
    // Add slight delay to show loading state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> _getMatchingFacilities() {
  if (currentQuery.isEmpty) return [];
  
  return facilities.where((facility) {
    List<String> keywords = List<String>.from(facility['keywords']);
    return keywords.any((keyword) =>
        keyword.toLowerCase().contains(currentQuery.toLowerCase()));
  }).toList();
}

  Widget _buildFacilityCard(Map<String, dynamic> facility) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: pricol.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            facility['icon'],
            width: 24,
            height: 24,
            color: pricol,
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
          'Tap to explore ${facility['name'].toLowerCase()}',
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

  Widget _buildEventsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireDb.getEventsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: pricol),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Filter events based on search query
        var filteredEvents = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String title = data['title']?.toString().toLowerCase() ?? '';
          String description = data['description']?.toString().toLowerCase() ?? '';
          String category = data['category']?.toString().toLowerCase() ?? '';
          
          return title.contains(currentQuery.toLowerCase()) ||
                 description.contains(currentQuery.toLowerCase()) ||
                 category.contains(currentQuery.toLowerCase());
        }).toList();

        if (filteredEvents.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Events',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2C2C),
                ),
              ),
            ),
            ...filteredEvents.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: yel.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar,
                      color: pricol,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Event',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
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
                      const SizedBox(height: 4),
                      if (data['date'] != null)
                        Text(
                          data['date'],
                          style: GoogleFonts.outfit(
                            color: pricol,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    color: pricol,
                    size: 18,
                  ),
                  onTap: () {
                    // Handle event tap - navigate to event details
                    // You can add event details page navigation here
                  },
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> matchingFacilities = _getMatchingFacilities();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                hintText: 'Search events, facilities...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                prefixIcon: const Icon(CupertinoIcons.search, color: pricol),
                suffixIcon: IconButton(
                  icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      currentQuery = '';
                    });
                  },
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
                    child: CircularProgressIndicator(color: pricol),
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
                              'Search for events and facilities',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching for "restaurants", "movies", "events"...',
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
                            if (matchingFacilities.isEmpty && currentQuery.isNotEmpty)
                              Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Center(
                                    child: Column(
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
                                          'Try searching for different keywords',
                                          style: GoogleFonts.outfit(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            
                            // Facilities Section
                            if (matchingFacilities.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Facilities',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2C2C2C),
                                  ),
                                ),
                              ),
                              ...matchingFacilities.map((facility) => _buildFacilityCard(facility)),
                              const SizedBox(height: 20),
                            ],
                            
                            // Events Section
                            _buildEventsSection(),
                            
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