import 'package:flutter/material.dart';



class PointsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(
            painter: TopBackgroundPainter(),
            child: Container(height: 200),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                  },
                ),
                SizedBox(width: 10),
                Text(
                  'Points',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: CustomPaint(
              size: Size(200, 200), 
              painter: PointsBadgePainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class TopBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Yellow curve
    var paintYellow = Paint()..color = Colors.yellow.shade700;
    var pathYellow = Path();
    pathYellow.lineTo(0, size.height * 0.6);
    pathYellow.quadraticBezierTo(size.width / 2, size.height * 0.9, size.width, size.height * 0.6);
    pathYellow.lineTo(size.width, 0);
    pathYellow.close();
    canvas.drawPath(pathYellow, paintYellow);

    var paintBlue = Paint()..color = Colors.indigo.shade900;
    var pathBlue = Path();
    pathBlue.lineTo(0, size.height * 0.7);
    pathBlue.quadraticBezierTo(size.width / 2, size.height, size.width, size.height * 0.7); // Deeper curve
    pathBlue.lineTo(size.width, 0);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class PointsBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double notchDepth = height * 0.15; 

    var borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    var badgePath = Path();
    badgePath.moveTo(0, height * 0.1); // Top-left rounded start (simplified)
    badgePath.lineTo(0, height - notchDepth); // Left edge
    badgePath.lineTo(width / 2, height); // Bottom point of the V
    badgePath.lineTo(width, height - notchDepth); // Right edge
    badgePath.lineTo(width, height * 0.1); 
    badgePath.quadraticBezierTo(width * 0.9, 0, width / 2, 0); // Top curve 
    badgePath.quadraticBezierTo(width * 0.1, 0, 0, height * 0.1); // Top curve 

    
    badgePath = Path();
    double topRadius = 15; 
    double sideOffset = width * 0.05;

    badgePath.moveTo(topRadius, 0); 
    badgePath.lineTo(width - topRadius, 0); // Top straight edge
    badgePath.arcToPoint(Offset(width, topRadius), radius: Radius.circular(topRadius)); // Top-right arc
    badgePath.lineTo(width, height - notchDepth); // Right vertical line
    badgePath.lineTo(width / 2, height); // Bottom peak
    badgePath.lineTo(0, height - notchDepth); // Left vertical line
    badgePath.arcToPoint(Offset(0, topRadius), radius: Radius.circular(topRadius), clockwise: false); // Top-left arc
    badgePath.close();

    canvas.drawPath(badgePath, borderPaint);

    var fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.yellow.shade100, // Lighter yellow at the top
          Colors.yellow.shade300, // Slightly darker yellow at the bottom
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    var innerBadgePath = Path();
    double innerPadding = 3.0; // Padding from the border
    innerBadgePath.moveTo(topRadius + innerPadding, innerPadding);
    innerBadgePath.lineTo(width - topRadius - innerPadding, innerPadding);
    innerBadgePath.arcToPoint(Offset(width - innerPadding, topRadius + innerPadding), radius: Radius.circular(topRadius));
    innerBadgePath.lineTo(width - innerPadding, height - notchDepth - innerPadding);
    innerBadgePath.lineTo(width / 2, height - innerPadding); // Adjust bottom peak for inner path
    innerBadgePath.lineTo(innerPadding, height - notchDepth - innerPadding);
    innerBadgePath.arcToPoint(Offset(innerPadding, topRadius + innerPadding), radius: Radius.circular(topRadius), clockwise: false);
    innerBadgePath.close();

    canvas.drawPath(innerBadgePath, fillPaint);

    // 3. Draw "Points Earned" text
    final textPainterPoints = TextPainter(
      text: TextSpan(
        text: 'Points Earned',
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterPoints.layout(minWidth: 0, maxWidth: width);
    textPainterPoints.paint(canvas, Offset((width - textPainterPoints.width) / 2, height * 0.2));

    // 4. Draw "56" text
    final textPainterNumber = TextPainter(
      text: TextSpan(
        text: '56',
        style: TextStyle(
          color: Colors.black,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterNumber.layout(minWidth: 0, maxWidth: width);
    textPainterNumber.paint(canvas, Offset((width - textPainterNumber.width) / 2, height * 0.4));

    var wingPaint = Paint()
      ..color = Colors.indigo.shade900
      ..style = PaintingStyle.fill;

  
    canvas.drawRect(Rect.fromLTWH(width * 0.15, height * 0.45, width * 0.1, 5), wingPaint);
    canvas.drawRect(Rect.fromLTWH(width * 0.15, height * 0.52, width * 0.08, 5), wingPaint);

    // Right wing
    canvas.drawRect(Rect.fromLTWH(width * 0.75, height * 0.45, width * 0.1, 5), wingPaint);
    canvas.drawRect(Rect.fromLTWH(width * 0.77, height * 0.52, width * 0.08, 5), wingPaint);

    // For precise wings:
    // var leftWingPath = Path();
    // leftWingPath.moveTo(width * 0.2, height * 0.45);
    // leftWingPath.cubicTo(...); // Add control points for curved wings
    // canvas.drawPath(leftWingPath, wingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}