import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/firebase/hotels_db.dart'; 

import 'package:url_launcher/url_launcher.dart';

class HotelSearch extends StatefulWidget {
  final String searchQuery;
  
  const HotelSearch({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<HotelSearch> createState() => _HotelSearchState();
}

class _HotelSearchState extends State<HotelSearch> {
  final HotelsDbService _hotelDb = HotelsDbService();
  final TextEditingController _searchController = TextEditingController();
  String currentQuery = '';
  bool isSearching = false;
  String selectedArea = 'All Areas';
  
  List<DocumentSnapshot> hotelResults = [];
  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    currentQuery = widget.searchQuery;
    _loadRecentSearches();
    
    if (currentQuery.isNotEmpty) {
      _performSearch();
    } else {
      _loadAllhotels();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() async {
    if (_hotelDb.getCurrentUser() != null) {
      List<String> searches = await _hotelDb.getRecenthotelsearchQueries(
        _hotelDb.getCurrentUser()!.uid
      );
      setState(() {
        recentSearches = searches;
      });
    }
  }

  void _loadAllhotels() async {
    setState(() {
      isSearching = true;
    });

    try {
      List<DocumentSnapshot> results;
      if (selectedArea == 'All Areas') {
        results = await _hotelDb.getAllhotels();
      } else {
        results = await _hotelDb.gethotelsByArea(selectedArea);
      }
      
      setState(() {
        hotelResults = results;
        isSearching = false;
      });
    } catch (e) {
      print('Error loading hotels: $e');
      setState(() {
        isSearching = false;
      });
    }
  }

  void _performSearch() async {
    setState(() {
      currentQuery = _searchController.text.trim();
      isSearching = true;
    });

    if (currentQuery.isEmpty) {
      _loadAllhotels();
      return;
    }

    try {
      List<DocumentSnapshot> results = await _hotelDb.searchhotelsByName(currentQuery);
      
      // Filter by selected area if not "All Areas"
      if (selectedArea != 'All Areas') {
        results = results.where((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String docArea = data['_area'] ?? '';
          return docArea == selectedArea;
        }).toList();
      }
      
      setState(() {
        hotelResults = results;
        isSearching = false;
      });

      if (_hotelDb.getCurrentUser() != null && currentQuery.isNotEmpty) {
        await _hotelDb.savehotelsearchQuery(
          _hotelDb.getCurrentUser()!.uid, 
          currentQuery
        );
        _loadRecentSearches();
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        isSearching = false;
      });
    }
  }

  

  Widget _buildhotelImage(String? imageUrl, {double width = 50, double height = 50, double radius = 8}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: const Icon(CupertinoIcons.plus_circled, color: Colors.green, size: 24),
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
                child: const Icon(CupertinoIcons.plus_circled, color: Colors.green, size: 24),
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
                child: const Icon(CupertinoIcons.plus_circled, color: Colors.green, size: 24),
              ),
            ),
    );
  }

  Widget _buildhotelCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: _buildhotelImage(data['imageUrl'], width: 50, height: 50, radius: 8),
        title: Text(
          data['name'] ?? 'hotel',
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
            if (data['location'] != null && data['location'].isNotEmpty)
              Text(
                data['location'],
                style: GoogleFonts.outfit(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                if (data['rating'] != null) ...[
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: Colors.amber,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data['rating'].toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          color: Colors.amber[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: data['siteUrl'] != null && data['siteUrl'].isNotEmpty
            ? IconButton(
                icon: const Icon(
                  CupertinoIcons.globe,
                  color: pricol,
                  size: 18,
                ),
                onPressed: () => _launchUrl(data['siteUrl']),
              )
            : const Icon(
                CupertinoIcons.chevron_right,
                color: pricol,
                size: 18,
              ),
        onTap: () => _showhotelDetails(doc),
      ),
    );
  }

  void _showhotelDetails(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    
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
                    _buildhotelImage(
                      data['imageUrl'], 
                      width: double.infinity, 
                      height: 200, 
                      radius: 12
                    ),
                    const SizedBox(height: 16),
                    
                    // hotel Name
                    Text(
                      data['name'] ?? 'hotel',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C2C2C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Location
                    if (data['location'] != null && data['location'].isNotEmpty)
                      Row(
                        children: [
                          const Icon(CupertinoIcons.location, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              data['location'],
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                       
                        if (data['rating'] != null) ...[
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                data['rating'].toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                  color: Colors.amber[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (data['siteUrl'] != null && data['siteUrl'].isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchUrl(data['siteUrl']),
                          icon: const Icon(CupertinoIcons.globe, color: Colors.white),
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
            SnackBar(
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
          SnackBar(
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
          'Search hotels',
          style: GoogleFonts.outfit(
            color: const Color.fromARGB(255, 21, 4, 62),
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
                hintText: 'Search hotels by name...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[600]),
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
                          });
                          _loadAllhotels();
                        },
                      ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.search, color: Color.fromARGB(255, 255, 230, 0)),
                      onPressed: _performSearch,
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: const Color.fromARGB(255, 255, 242, 0)!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color.fromARGB(255, 255, 251, 0), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.outfit(fontSize: 16),
            ),
          ),
          
          // 
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
                        Text('Searching hotels...'),
                      ],
                    ),
                  )
                : hotelResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currentQuery.isEmpty 
                                  ? CupertinoIcons.plus_circled
                                  : CupertinoIcons.exclamationmark_circle,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentQuery.isEmpty 
                                  ? 'Search for hotels'
                                  : 'No hotels found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentQuery.isEmpty 
                                  ? 'Find hotels by name in Calicut and Kattangal'
                                  : 'Try different keywords or change area filter',
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
                              '${hotelResults.length} hotel${hotelResults.length == 1 ? '' : 's'} found',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: hotelResults.length,
                              itemBuilder: (context, index) {
                                return _buildhotelCard(hotelResults[index]);
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