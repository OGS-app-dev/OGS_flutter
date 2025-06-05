import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdsViewAll extends StatelessWidget {
  final double height;
  final double width;
  final Color bgCol;
  final double outBorderRadius;
  final bool hasChild;

  const AdsViewAll({
    super.key,
    this.height = 150,
    this.width = 120,
    this.bgCol = Colors.white,
    this.outBorderRadius = 15,
    this.hasChild = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sample data for the cards
    final List<Map<String, String>> cardData = [
      {
        'title': '#AD1',
        'location': '',
        'image': '',
        'color': 'purple',
      },
      {
        'title': 'Tathva 2024',
        'location': 'NIT Calicut',
        'image': 'lib/assets/images/tathva.png',
        'color': 'black',
      },
      {
        'title': 'Ragam 2024',
        'location': 'NIT Calicut',
        'image': 'lib/assets/images/ragam.png',
        'color': 'black',
      },
      {
        'title': 'IEDC Summit 2024',
        'location': 'NIT Calicut',
        'image': '',
        'color': 'black',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Container(
        color: const Color.fromARGB(255, 255, 255, 255),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: cardData.length,
          itemBuilder: (context, index) {
            final data = cardData[index];
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(outBorderRadius),
                    color: bgCol,
                  ),
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.all(15),
                  child: hasChild
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: data['color'] == 'purple'
                                      ? const Color.fromARGB(255, 78, 2, 255)
                                      : Colors.black,
                                ),
                                child: data['image']!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Image.asset(
                                          data['image']!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error,
                                                      size: 50,
                                                      color: Colors.red),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              data['title']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 41, 41, 49),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              data['location']!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 137, 137, 137),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Container(
                    width: 28,
                    height: 28,
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
                      size: 14,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
