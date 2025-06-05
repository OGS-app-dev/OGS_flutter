import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class UnifiedSearchPage extends StatefulWidget {
  final String searchQuery;

  const UnifiedSearchPage({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<UnifiedSearchPage> createState() => _UnifiedSearchPageState();
}

class _UnifiedSearchPageState extends State<UnifiedSearchPage> {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String currentQuery = '';
  bool isSearching = false;
  List<SearchResult> searchResults = [];
  List<String> recentSearches = [];

  // All collections to search through - Updated with new collections
  final Map<String, String> collections = {
    'res_kattangal': 'Restaurant',
    'res_calicut': 'Restaurant',
    'movies_now': 'Movie (Now Playing)',
    'movies_upcom': 'Movie (Upcoming)',
    'hotels_kattangal': 'Hotel',
    'hotels_calicut': 'Hotel',
    'petrol_pumps': 'Petrol Pump',
    'events': 'Event',
    'hospitals_kattangal': 'Hospital',
    'hospitals_calicut': 'Hospital',
  };

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    currentQuery = widget.searchQuery;
    _loadRecentSearches();

    if (currentQuery.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() async {
    if (_auth.currentUser != null) {
      try {
        QuerySnapshot snapshot = await _firebase
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('unifiedSearchHistory')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .get();

        setState(() {
          recentSearches = snapshot.docs
              .map((doc) =>
                  (doc.data() as Map<String, dynamic>)['query'] as String)
              .toList();
        });
      } catch (e) {
        print('Error loading recent searches: $e');
      }
    }
  }

  void _performSearch() async {
    setState(() {
      currentQuery = _searchController.text.trim();
      isSearching = true;
      searchResults.clear();
    });

    if (currentQuery.isEmpty) {
      setState(() {
        isSearching = false;
      });
      return;
    }

    try {
      String lowerQuery = currentQuery.toLowerCase();
      List<SearchResult> allResults = [];

      // Search through all collections
      for (String collectionName in collections.keys) {
        String category = collections[collectionName]!;

        QuerySnapshot snapshot =
            await _firebase.collection(collectionName).get();

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String name =
              (data['name'] ?? data['title'] ?? '').toString().toLowerCase();

          // Check for matches
          if (name.contains(lowerQuery) ||
              lowerQuery.contains(name) ||
              name
                  .replaceAll('-', '')
                  .contains(lowerQuery.replaceAll('-', '')) ||
              name
                  .replaceAll(' ', '')
                  .contains(lowerQuery.replaceAll(' ', ''))) {
            allResults.add(SearchResult(
              id: doc.id,
              name: data['name'] ?? data['title'] ?? 'Unknown',
              category: category,
              collection: collectionName,
              data: data,
              relevanceScore: _calculateRelevance(name, lowerQuery),
            ));
          }
        }
      }

      // Sort by relevance and then alphabetically
      allResults.sort((a, b) {
        int relevanceCompare = b.relevanceScore.compareTo(a.relevanceScore);
        if (relevanceCompare != 0) return relevanceCompare;
        return a.name.compareTo(b.name);
      });

      setState(() {
        searchResults = allResults;
        isSearching = false;
      });

      // Save search query
      if (_auth.currentUser != null && currentQuery.isNotEmpty) {
        await _saveSearchQuery(currentQuery);
        _loadRecentSearches();
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        isSearching = false;
      });
    }
  }

  int _calculateRelevance(String name, String query) {
    if (name == query) return 100; // Exact match
    if (name.startsWith(query)) return 90; // Starts with query
    if (name.contains(query)) return 80; // Contains query
    return 50; // Other matches
  }

  Future<void> _saveSearchQuery(String query) async {
    try {
      await _firebase
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('unifiedSearchHistory')
          .add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Keep only last 20 searches
      QuerySnapshot oldSearches = await _firebase
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('unifiedSearchHistory')
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
      print('Error saving search query: $e');
    }
  }

  // Get appropriate icon for each category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
        return CupertinoIcons.house;
      case 'movie (now playing)':
      case 'movie (upcoming)':
        return CupertinoIcons.film;
      case 'hotel':
        return CupertinoIcons.bed_double;
      case 'petrol pump':
        return CupertinoIcons.car;
      case 'event':
        return CupertinoIcons.calendar;
      case 'hospital':
        return CupertinoIcons.plus_circle;
      default:
        return CupertinoIcons.info;
    }
  }

  Widget _buildItemImage(Map<String, dynamic> data,
      {double width = 50, double height = 50, double radius = 8}) {
    String? imageUrl = data['imageUrl'] ?? data['image'] ?? data['poster'];

    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: const Icon(CupertinoIcons.photo, color: Colors.green, size: 24),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl.startsWith('http')
          ? Image.network(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: pricol,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: const Icon(CupertinoIcons.photo,
                    color: Colors.green, size: 24),
              ),
            )
          : Image.asset(
              imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: const Icon(CupertinoIcons.photo,
                    color: Colors.green, size: 24),
              ),
            ),
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _buildItemImage(result.data, width: 50, height: 50, radius: 8),
        title: Text(
          result.name,
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
            Row(
              children: [
                Icon(
                  _getCategoryIcon(result.category),
                  size: 12,
                  color: pricol,
                ),
                const SizedBox(width: 4),
                Text(
                  result.category,
                  style: GoogleFonts.outfit(
                    color: pricol,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (result.data['location'] != null &&
                result.data['location'].isNotEmpty)
              Text(
                result.data['location'],
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // Show event date for events
            if (result.category == 'Event' && result.data['date'] != null)
              Text(
                result.data['date'],
                style: GoogleFonts.outfit(
                  color: Colors.orange[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            // Show rating if available
            if (result.data['rating'] != null)
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    color: Colors.amber,
                    size: 12,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    result.data['rating'].toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      color: Colors.amber[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing:
            result.data['siteUrl'] != null && result.data['siteUrl'].isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      CupertinoIcons.globe,
                      color: pricol,
                      size: 18,
                    ),
                    onPressed: () => _launchUrl(result.data['siteUrl']),
                  )
                : const Icon(
                    CupertinoIcons.chevron_right,
                    color: pricol,
                    size: 18,
                  ),
        onTap: () => _showItemDetails(result),
      ),
    );
  }

  void _showItemDetails(SearchResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemImage(result.data,
                        width: double.infinity, height: 200, radius: 12),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      result.name,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category with icon
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pricol.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(result.category),
                            size: 14,
                            color: pricol,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            result.category,
                            style: GoogleFonts.outfit(
                              color: pricol,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Location
                    if (result.data['location'] != null &&
                        result.data['location'].isNotEmpty)
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location,
                              color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              result.data['location'],
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Event date
                    if (result.category == 'Event' &&
                        result.data['date'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.calendar,
                              color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            result.data['date'],
                            style: GoogleFonts.outfit(
                              color: Colors.orange[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Rating
                    if (result.data['rating'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.star_fill,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            result.data['rating'].toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              color: Colors.amber[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Description for events and hospitals
                    if ((result.category == 'Event' ||
                            result.category == 'Hospital') &&
                        result.data['description'] != null &&
                        result.data['description'].isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C2C2C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.data['description'],
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Website button
                    if (result.data['siteUrl'] != null &&
                        result.data['siteUrl'].isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchUrl(result.data['siteUrl']),
                          icon: const Icon(CupertinoIcons.globe,
                              color: Colors.white),
                          label: Text(
                            'Visit Website',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pricol,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open website'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening website'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRecentSearches() {
    if (recentSearches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Recent Searches',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: recentSearches.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    recentSearches[index],
                    style: GoogleFonts.outfit(fontSize: 12),
                  ),
                  onPressed: () {
                    _searchController.text = recentSearches[index];
                    _performSearch();
                  },
                  backgroundColor: Colors.grey[100],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            color: pricol,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onSubmitted: (value) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Explore Events and More...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill,
                            color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            currentQuery = '';
                            searchResults.clear();
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.search,
                        color: yel,
                      ),
                      onPressed: _performSearch,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: yel,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: yel, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.outfit(fontSize: 16),
            ),
          ),

          const SizedBox(height: 8),

          // Recent Searches
          if (currentQuery.isEmpty) _buildRecentSearches(),

          // Results
          Expanded(
            child: isSearching
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: pricol),
                        SizedBox(height: 16),
                        Text('Searching...'),
                      ],
                    ),
                  )
                : searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currentQuery.isEmpty
                                  ? CupertinoIcons.search
                                  : CupertinoIcons.exclamationmark_circle,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentQuery.isEmpty
                                  ? 'Start searching'
                                  : 'No results found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentQuery.isEmpty
                                  ? 'Find restaurants, movies, hotels, hospitals, events, and petrol pumps'
                                  : 'Try different keywords',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text(
                              '${searchResults.length} result${searchResults.length == 1 ? '' : 's'} found',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                return _buildResultCard(searchResults[index]);
                              },
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class SearchResult {
  final String id;
  final String name;
  final String category;
  final String collection;
  final Map<String, dynamic> data;
  final int relevanceScore;

  SearchResult({
    required this.id,
    required this.name,
    required this.category,
    required this.collection,
    required this.data,
    required this.relevanceScore,
  });
}
