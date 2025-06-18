import 'package:flutter/material.dart';
import 'package:ogs/pages/comingsoon.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:ticket_widget/ticket_widget.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({
    super.key,
  });

  @override
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          Stack(
            children: [
              CustomPaint(
                painter: CurvePainter(),
                child: Container(height: 180),
              ),
              Positioned(
                top: 70,
                left: 20,
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.yellow, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Color.fromARGB(255, 0, 0, 0), size: 20),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Vouchers',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: voucherCard(index),
                );
              },
            ),
          ),
          SizedBox(height: 60,)
        ],
      ),
    );
  }

  Widget voucherCard(int index) {
    // Different voucher types for variety
    final voucherData = [
      {
        'title': '26% OFF on Movie tickets',
        'subtitle': 'Valid till 31st Dec',
        'image': 'lib/assets/images/mov.png',
        'colors': [const Color(0xFF6A5ACD), const Color(0xFF483D8B)],
      },
      {
        'title': '15% OFF on Restaurants',
        'subtitle': 'Min order ₹500',
        'image': 'lib/assets/images/res.png',
        'colors': [const Color(0xFFFF6347), const Color(0xFFDC143C)],
      },
      {
        'title': 'Buy 1 Get 1 FREE',
        'subtitle': 'On selected items',
        'image': 'lib/assets/images/mov.png',
        'colors': [const Color(0xFF32CD32), const Color(0xFF228B22)],
      },
      {
        'title': '30% OFF on Fashion',
        'subtitle': 'Use code: STYLE30',
        'image': 'lib/assets/images/res.png',
        'colors': [const Color(0xFFFF1493), const Color(0xFFDC143C)],
      },
      {
        'title': '₹200 Cashback',
        'subtitle': 'On orders above ₹1000',
        'image': 'lib/assets/images/mov.png',
        'colors': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      },
    ];

    final data = voucherData[index % voucherData.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: CustomTicketWidget(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 160,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: data['colors'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative pattern overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              
              // Decorative circles
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Left side - Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          data['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.local_offer,
                                color: Colors.grey.shade600,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Right side - Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            data['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: data['colors'] != null 
                                    ? (data['colors'] as List<Color>)[0] 
                                    : Colors.indigo,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24, 
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ComingSoon(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Redeem Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Ticket Widget with 3 small cuts on each side
class CustomTicketWidget extends StatelessWidget {
  final Widget child;
  final double width;
  final double height;

  const CustomTicketWidget({
    Key? key,
    required this.child,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TicketClipper(),
      child: Container(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    
    const double cutRadius = 10.0; // Radius of the semicircular cuts
    const double cornerRadius = 0.0; // Corner radius
    
    // Calculate positions for 3 cuts on each side
    final double cutSpacing = (size.height - 6 * cutRadius) / 4;
    
    // Start from top-left corner
    path.moveTo(cornerRadius, 0);
    
    // Top edge
    path.lineTo(size.width - cornerRadius, 0);
    
    // Top-right corner
    path.arcToPoint(
      Offset(size.width, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Right edge with 3 cuts
    double rightY = cornerRadius;
    
    // Move to first cut position
    rightY += cutSpacing;
    path.lineTo(size.width, rightY);
    
    // First cut on right side
    path.arcToPoint(
      Offset(size.width, rightY + 2 * cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );
    
    // Move to second cut position
    rightY += 2 * cutRadius + cutSpacing;
    path.lineTo(size.width, rightY);
    
    // Second cut on right side
    path.arcToPoint(
      Offset(size.width, rightY + 2 * cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );
    
    // Move to third cut position
    rightY += 2 * cutRadius + cutSpacing;
    path.lineTo(size.width, rightY);
    
    // Third cut on right side
    path.arcToPoint(
      Offset(size.width, rightY + 2 * cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );
    
    // Continue to bottom-right corner
    path.lineTo(size.width, size.height - cornerRadius);
    
    // Bottom-right corner
    path.arcToPoint(
      Offset(size.width - cornerRadius, size.height),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Bottom edge
    path.lineTo(cornerRadius, size.height);
    
    // Bottom-left corner
    path.arcToPoint(
      Offset(0, size.height - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );
    
    // Left edge with 3 cuts (from bottom to top)
    double leftY = size.height - cornerRadius;
    
    // Move to first cut position (from bottom)
    leftY -= cutSpacing;
    path.lineTo(0, leftY);
    
    // First cut on left side (bottom)
    path.arcToPoint(
      Offset(0, leftY - 2 * cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );
    
    // Move to second cut position
    leftY -= 2 * cutRadius + cutSpacing;
    path.lineTo(0, leftY);
    
    // Second cut on left side
    path.arcToPoint(
      Offset(0, leftY - 2 * cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );
    
    // Move to third cut position
    leftY -= 2 * cutRadius + cutSpacing;
    path.lineTo(0, leftY);
    
    // Third cut on left side (top)
    path.arcToPoint(
      Offset(0, leftY - 2 * cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );
    
    // Continue to top-left corner
    path.lineTo(0, cornerRadius);
    
    // Top-left corner
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paintBlue = Paint()..color = Colors.indigo.shade900;
    var pathBlue = Path();

    pathBlue.moveTo(0, size.height * 0.7);
    pathBlue.quadraticBezierTo(
        size.width / 2, size.height * 0.85, size.width, size.height * 0);
    pathBlue.lineTo(size.width, size.height);
    pathBlue.lineTo(0, size.height);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);

    var paintYellow = Paint()..color = const Color(0xFFFFDA45);
    var pathYellow = Path();

    pathYellow.moveTo(0, 0.2);
    pathYellow.lineTo(size.width * 1.1, 0);
    pathYellow.quadraticBezierTo(
        size.width * 0.9, size.height * 0.9, 0.1, size.height * 0.9);
    pathYellow.close();
    canvas.drawPath(pathYellow, paintYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}