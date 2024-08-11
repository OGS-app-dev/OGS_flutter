import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HorizontalScrollTile extends StatelessWidget {
  final double height;
  final double width;
  final Color bgCol;
  final double outBorderRadius;
  final bool hasChild;

  const HorizontalScrollTile({
    super.key,
    this.height = 150,
    this.width = 120,
    this.bgCol = const Color.fromARGB(255, 245, 245, 245),
    this.outBorderRadius = 15,
    this.hasChild = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(outBorderRadius),
                  color: bgCol,
                ),
                height: height,
                width: width,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(15),
                child: hasChild
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "  Tathva 2024",
                            style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 41, 41, 49),
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 1),
                          ),
                          Text(
                            "   NIT Calicut",
                            style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 137, 137, 137),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: 1),
                          )
                        ],
                      )
                    : null,
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
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(outBorderRadius),
                  color: bgCol,
                ),
                height: height,
                width: width,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(15),
                child: hasChild
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "  Ragam 2024",
                            style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 41, 41, 49),
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 1),
                          ),
                          Text(
                            "   NIT Calicut",
                            style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 137, 137, 137),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: 1),
                          )
                        ],
                      )
                    : null,
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
                        )
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.play_arrow,
                      color: Colors.white,
                      size: 15,
                    ),
                  ))
            ],
          ),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(outBorderRadius),
                  color: bgCol,
                ),
                height: height,
                width: width,
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(15),
                child: hasChild
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.grey[300],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "  IEDC Summit 2024",
                            style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 41, 41, 49),
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                letterSpacing: 1),
                          ),
                          Text(
                            "   NIT Calicut",
                            style: GoogleFonts.outfit(
                                color: const Color.fromARGB(255, 137, 137, 137),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                letterSpacing: 1),
                          )
                        ],
                      )
                    : null,
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
                        )
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.play_arrow,
                      color: Colors.white,
                      size: 15,
                    ),
                  ))
            ],
          ),
        ],
      ),
    );
  }
}
