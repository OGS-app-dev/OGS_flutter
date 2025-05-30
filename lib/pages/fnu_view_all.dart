import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ogs/models/hospital_model.dart';
import 'package:url_launcher/url_launcher.dart'; 


class ViewAllPage extends StatefulWidget {
  final String pageTitle;
  final String nameCollection;

  const ViewAllPage({
    super.key,
    required this.pageTitle,
    required this.nameCollection
  });
  @override
  State<ViewAllPage> createState() => _ViewAllPageState();
}

class _ViewAllPageState extends State<ViewAllPage> {
   Future<void> _launchUrl(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link: $url')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(widget.pageTitle,style: const TextStyle(fontSize: 17,fontWeight: FontWeight.bold),),
      ),
      body:
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10), 
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _buildFirebasehospitalsection(
                      widget.pageTitle, widget.nameCollection),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildFirebasehospitalsection(String title, String collectionName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(collectionName)
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading details',
                    style: GoogleFonts.outfit(color: Colors.red),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SpinKitThreeBounce(
                    size: 20,
                    color: pricol,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No data found in $title',
                    style: GoogleFonts.outfit(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final hospital = snapshot.data!.docs;

              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0, 
                  childAspectRatio:
                      0.9, 
                ),
                itemCount: hospital.length,
                itemBuilder: (context, index) {
                  final hospitals = Hospital.fromFirestore(hospital[index]
                      as DocumentSnapshot<Map<String, dynamic>>);
                  return _buildhospitalsCard(hospitals);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildhospitalsCard(Hospital hospitals) {
    return GestureDetector(
      onTap: () {
        if (hospitals.siteUrl != null && hospitals.siteUrl!.isNotEmpty) {
        _launchUrl(context, hospitals.siteUrl!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No website available for ${hospitals.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          // boxShadow: [
          //   BoxShadow(
          //     color: Colors.grey.withOpacity(0.2),
          //     spreadRadius: 1,
          //     blurRadius: 5,
          //     offset: const Offset(0, 3),
          //   ),
          // ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.all( Radius.circular(10)),
                  child: hospitals.imageUrl.startsWith('http')
                      ? Image.network(
                          hospitals.imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.fill,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 130,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: pricol,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 130,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            );
                          },
                        )
                      : Image.asset(
                          hospitals.imageUrl,
                          height: 130,
                          width: double.infinity,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 130,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey),
                            );
                          },
                        ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitals.name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (hospitals.rating != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            hospitals.rating!.toStringAsFixed(1),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      hospitals.location,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
}