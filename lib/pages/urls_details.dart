import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ogs/models/event_model.dart';
import 'package:url_launcher/url_launcher.dart'; 

class UrlDetailsPage extends StatelessWidget {
  final Event event; // The event object to display

  const UrlDetailsPage({Key? key, required this.event}) : super(key: key);
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Events',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: event.imageUrl.startsWith('http')
                      ? Image.network(
                          event.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  size: 50, color: Colors.grey),
                        )
                      : Image.asset(
                          event
                              .imageUrl, // This will be "assets/images/ragam_logo.png"
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error,
                                  size: 50, color: Colors.red), // Asset errors
                        ),
                ),
                if (event.isLive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Live',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
               
              ],
            ),
             Padding(
               padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
               child: Text(
                 event.name,
                 style: GoogleFonts.outfit(
                   color: Colors.white,
                   fontWeight: FontWeight.w800,
                   fontSize: 32,
                   shadows: [
                     Shadow(
                       offset: const Offset(1, 1),
                       blurRadius: 3.0,
                       color: Colors.black.withOpacity(0.6),
                     ),
                   ],
                 ),
                 maxLines: 2,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  

                  
                  if (event.siteUrl != null && event.siteUrl!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _launchUrl(context, event.siteUrl!);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 218, 215, 204),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shadowColor:
                              Colors.transparent, // Explicitly no shadow
                        ),
                        child: Text(
                          'Visit ',
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(
              height: 80,
            )
          ],
        ),
      ),
    );
  }
}
