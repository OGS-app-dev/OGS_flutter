import 'package:flutter/material.dart';
import 'dart:math' as math; 


class PointsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Stack(
        children: [
          CustomPaint(
            painter: CurvePainter(),
            child: Container(height: 200),
          ),
          Positioned(
            top: 70,
            left: 20,
            child: Row(
              children: [
                Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.white], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0), size: 20), 
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
                const SizedBox(width: 10),
                const Text(
                  'Points',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color:  Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
            padding: const EdgeInsets.all(20),
            color: const Color.fromARGB(255, 255, 252, 252),
            child: CustomPaint(
              size: const Size(350, 250), 
              painter: PentagonBadgePainter(),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paintBlue = Paint()..color = Colors.indigo.shade900;
    var pathBlue = Path();

    pathBlue.moveTo(0, size.height * 0.7); 
    pathBlue.quadraticBezierTo(size.width / 2, size.height * 0.85, size.width, size.height * 0);
    pathBlue.lineTo(size.width, size.height);
    pathBlue.lineTo(0, size.height);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);

    var paintYellow = Paint()..color = Color(0xFFFFDA45);
    var pathYellow = Path();

    pathYellow.moveTo(0, 0.2);
    pathYellow.lineTo(size.width*1.1, 0);
    pathYellow.quadraticBezierTo(size.width *0.9, size.height * 0.9, 0.1, size.height * 0.9);
    pathYellow.close();
    canvas.drawPath(pathYellow, paintYellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }}


class PentagonBadgePainter extends CustomPainter {
  void _drawYellowWings(Canvas canvas, double width, double height) {
    var yellowPaint = Paint()
      ..color = const Color.fromARGB(255, 255, 193, 7) // Golden yellow
      ..style = PaintingStyle.fill;

    double wingWidth = width * 0.15;
    double wingHeight = height * 0.08;
    double centerY = height * 0.42; // Align with the number

    // Left wing (3 stacked rounded rectangles)
    double leftWingCenterX = width * 0.22;
    
    // Top wing segment
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(leftWingCenterX, centerY - wingHeight * 0.9),
          width: wingWidth * 2,
          height: wingHeight * 0.5,
        ),
        topLeft: Radius.circular(wingHeight * 0.25),
        topRight: Radius.circular(wingHeight * 0.25),
        bottomLeft: Radius.circular(wingHeight * 0.25),
        bottomRight: Radius.circular(wingHeight * 0.25),
      ),
      yellowPaint,
    );

    // Middle wing segment (largest)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(leftWingCenterX, centerY),
          width: wingWidth*1.5,
          height: wingHeight * 0.6,
        ),
        topLeft: Radius.circular(wingHeight * 0.3),
        topRight: Radius.circular(wingHeight * 0.3),
        bottomLeft: Radius.circular(wingHeight * 0.3),
        bottomRight: Radius.circular(wingHeight * 0.3),
      ),
      yellowPaint,
    );

    // Bottom wing segment
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(leftWingCenterX, centerY + wingHeight * 0.9),
          width: wingWidth ,
          height: wingHeight * 0.5,
        ),
        topLeft: Radius.circular(wingHeight * 0.25),
        topRight: Radius.circular(wingHeight * 0.25),
        bottomLeft: Radius.circular(wingHeight * 0.25),
        bottomRight: Radius.circular(wingHeight * 0.25),
      ),
      yellowPaint,
    );

    // Right wing (3 stacked rounded rectangles)
    double rightWingCenterX = width * 0.78;
    
    // Top wing segment
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(rightWingCenterX, centerY - wingHeight * 0.9),
          width: wingWidth *2,
          height: wingHeight * 0.5,
        ),
        topLeft: Radius.circular(wingHeight * 0.5),
        topRight: Radius.circular(wingHeight * 0.5),
        bottomLeft: Radius.circular(wingHeight * 0.5),
        bottomRight: Radius.circular(wingHeight * 0.5),
      ),
      yellowPaint,
    );

    // Middle wing segment (largest)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(rightWingCenterX, centerY),
          width: wingWidth*1.5,
          height: wingHeight * 0.6,
        ),
        topLeft: Radius.circular(wingHeight * 0.5),
        topRight: Radius.circular(wingHeight * 0.5),
        bottomLeft: Radius.circular(wingHeight * 0.5),
        bottomRight: Radius.circular(wingHeight * 0.5),
      ),
      yellowPaint,
    );

    // Bottom wing segment
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(rightWingCenterX, centerY + wingHeight * 0.9),
          width: wingWidth ,
          height: wingHeight * 0.5,
        ),
        topLeft: Radius.circular(wingHeight * 0.5),
        topRight: Radius.circular(wingHeight * 0.5),
        bottomLeft: Radius.circular(wingHeight * 0.5),
        bottomRight: Radius.circular(wingHeight * 0.5),
      ),
      yellowPaint,
    );
  }
   void _drawYellowline(Canvas canvas, double width, double height) {
    var yellowPaint = Paint()
      ..color = const Color.fromARGB(255, 255, 193, 7) // Golden yellow
      ..style = PaintingStyle.fill;

    double lineWidth = width * 0.9; // 90% of badge width
    double lineHeight = height * 0.04; // Thinner line
    double centerY = height * 0.08; // Position at top, above trophy

    // Yellow top line (full width, rounded)
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(width / 2, centerY),
          width: lineWidth,
          height: lineHeight,
        ),
        topLeft: Radius.circular(lineHeight * 0.5),
        topRight: Radius.circular(lineHeight * 0.5),
        bottomLeft: Radius.circular(lineHeight * 0.5),
        bottomRight: Radius.circular(lineHeight * 0.5),
      ),
      yellowPaint,
    );
  }


  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width;
    double height = size.height;
    double topRadius = 25.0; // Radius for the curved top corners (adjust as needed)

    // --- Paint for the Border ---
    var borderPaint = Paint()
      ..color = const Color.fromARGB(255, 6, 2, 46) // Deep blue border
      ..style = PaintingStyle.stroke // Draw only the border
      ..strokeWidth = 0.0; // Thickness of the border

    // --- Paint for the Inner Fill ---
    var fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color.fromARGB(255, 14, 3, 85), // Lighter blue at the top
          const Color.fromARGB(255, 19, 1, 56), // Darker blue at the bottom
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height)); // Shader covers the entire badge area

    // --- Outer Badge Path (Pentagon-like shape with curved top edges and straight vertical sides) ---
    var badgePath = Path();

    // Define the key points for the outer pentagon shape with straight vertical sides

    // 1. Start point for the top straight line (after the top-left curve)
    Offset topLeftStraightStart = Offset(topRadius, 0);
    // 2. End point for the top straight line (before the top-right curve)
    Offset topRightStraightEnd = Offset(width - topRadius, 0);

    // 3. Point where the top-right curve ends and the RIGHT VERTICAL side begins
    Offset topRightCurveEnd = Offset(width, topRadius);
    // 4. Point where the top-left curve ends and the LEFT VERTICAL side begins
    Offset topLeftCurveStart = Offset(0, topRadius);

    // 5. Bottom-right vertex - STRAIGHT DOWN from the top-right curve end
    double verticalSideHeight = height * 0.7; // How far down the vertical sides go
    Offset bottomRightVertex = Offset(width, verticalSideHeight); // Same X as topRightCurveEnd

    // 6. Bottom-center vertex (the sharp peak of the pentagon)
    Offset bottomCenterVertex = Offset(width / 2, height);

    // 7. Bottom-left vertex - STRAIGHT DOWN from the top-left curve start
    Offset bottomLeftVertex = Offset(0, verticalSideHeight); // Same X as topLeftCurveStart

    // --- Drawing the Outer Path ---
    // Move to the start of the top straight line
    badgePath.moveTo(topLeftStraightStart.dx, topLeftStraightStart.dy);

    // 1. Draw the top straight line
    badgePath.lineTo(topRightStraightEnd.dx, topRightStraightEnd.dy);

    // 2. Draw the top-right arc (from `topRightStraightEnd` to `topRightCurveEnd`)
    badgePath.arcToPoint(
      topRightCurveEnd,
      radius: Radius.circular(topRadius),
      clockwise: true, // Arc clockwise
    );

    // 3. Draw the RIGHT VERTICAL line (straight down)
    badgePath.lineTo(bottomRightVertex.dx, bottomRightVertex.dy);

    // 4. Draw the bottom-right line segment (from `bottomRightVertex` to `bottomCenterVertex` - the peak)
    badgePath.lineTo(bottomCenterVertex.dx, bottomCenterVertex.dy);

    // 5. Draw the bottom-left line segment (from `bottomCenterVertex` - the peak to `bottomLeftVertex`)
    badgePath.lineTo(bottomLeftVertex.dx, bottomLeftVertex.dy);

    // 6. Draw the LEFT VERTICAL line (straight up)
    badgePath.lineTo(topLeftCurveStart.dx, topLeftCurveStart.dy);

    // 7. Draw the top-left arc (from `topLeftCurveStart` back to `topLeftStraightStart` - closing the path)
    badgePath.arcToPoint(
      topLeftStraightStart,
      radius: Radius.circular(topRadius),
      clockwise: true, // Arc clockwise to connect back to the start
    );

    badgePath.close(); // Ensure the path is closed

    canvas.drawPath(badgePath, borderPaint); // Draw the outer border

    // --- Inner Badge Path (Fill Area) ---
    var innerBadgePath = Path();
    double innerPadding = 3.0; // Padding from the border for the inner fill

    // Adjust topRadius for the inner path, ensuring it doesn't go negative
    double innerTopRadius = math.max(0, topRadius - innerPadding);

    // Calculate inner path points based on outer path points and padding.
    Offset innerTopLeftStraightStart = Offset(topLeftStraightStart.dx + innerPadding, topLeftStraightStart.dy + innerPadding);
    Offset innerTopRightStraightEnd = Offset(topRightStraightEnd.dx - innerPadding, topRightStraightEnd.dy + innerPadding);

    Offset innerTopRightCurveEnd = Offset(topRightCurveEnd.dx - innerPadding, topRightCurveEnd.dy + innerPadding);
    Offset innerTopLeftCurveStart = Offset(topLeftCurveStart.dx + innerPadding, topLeftCurveStart.dy + innerPadding);

    // Adjust for straight vertical sides - keep the same X coordinates but adjust for padding
    Offset innerBottomRightVertex = Offset(bottomRightVertex.dx - innerPadding, bottomRightVertex.dy - innerPadding);
    Offset innerBottomCenterVertex = Offset(bottomCenterVertex.dx, bottomCenterVertex.dy - innerPadding);
    Offset innerBottomLeftVertex = Offset(bottomLeftVertex.dx + innerPadding, bottomLeftVertex.dy - innerPadding);

    // --- Drawing the Inner Path ---
    innerBadgePath.moveTo(innerTopLeftStraightStart.dx, innerTopLeftStraightStart.dy);

    // Inner 1. Top straight line
    innerBadgePath.lineTo(innerTopRightStraightEnd.dx, innerTopRightStraightEnd.dy);

    // Inner 2. Top-right arc
    innerBadgePath.arcToPoint(
      innerTopRightCurveEnd,
      radius: Radius.circular(innerTopRadius),
      clockwise: true,
    );

    // Inner 3. Right VERTICAL line (straight down)
    innerBadgePath.lineTo(innerBottomRightVertex.dx, innerBottomRightVertex.dy);

    // Inner 4. Bottom-right line
    innerBadgePath.lineTo(innerBottomCenterVertex.dx, innerBottomCenterVertex.dy);

    // Inner 5. Bottom-left line
    innerBadgePath.lineTo(innerBottomLeftVertex.dx, innerBottomLeftVertex.dy);

    // Inner 6. Left VERTICAL line (straight up)
    innerBadgePath.lineTo(innerTopLeftCurveStart.dx, innerTopLeftCurveStart.dy);

    // Inner 7. Top-left arc
    innerBadgePath.arcToPoint(
      innerTopLeftStraightStart,
      radius: Radius.circular(innerTopRadius),
      clockwise: true,
    );

    innerBadgePath.close(); // Ensure the inner path is closed

    canvas.drawPath(innerBadgePath, fillPaint); // Draw the inner fill
_drawYellowline(canvas, width, height);
    // --- Draw Trophy Icon ---
    _drawIconFromData(canvas, Icons.emoji_events.codePoint, width / 2, height * 0.2, 40.0);

    // --- Draw Number Text ---
    final textPainterNumber = TextPainter(
      text: TextSpan(
        text: '56',
        style: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255),
          fontSize: 88,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterNumber.layout(minWidth: 0, maxWidth: width);
    textPainterNumber.paint(canvas, Offset((width - textPainterNumber.width) / 2, height * 0.25));

    // --- Draw Yellow Decorative Wings ---
    _drawYellowWings(canvas, width, height);

    // --- Draw Points Text ---
    final textPainterPoints = TextPainter(
      text:const TextSpan(
        text: 'Points',
        style: TextStyle(
          color: const Color.fromARGB(255, 255, 255, 255),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainterPoints.layout(minWidth: 0, maxWidth: width);
    textPainterPoints.paint(canvas, Offset((width - textPainterPoints.width) / 2, height * 0.65));
  }
void _drawIconFromData(Canvas canvas, int codePoint, double centerX, double centerY, double size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(codePoint),
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: size,
          color: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2)
    );
  }
  void _drawTrophy(Canvas canvas, double centerX, double centerY, double size) {
    var trophyPaint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..style = PaintingStyle.fill;

    // Trophy cup (main body)
    var cupPath = Path();
    double cupWidth = size * 0.8;
    double cupHeight = size * 0.6;
    
    // Cup body - rounded rectangle
    cupPath.addRRect(RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(centerX, centerY - size * 0.1),
        width: cupWidth,
        height: cupHeight,
      ),
      topLeft: Radius.circular(size * 0.1),
      topRight: Radius.circular(size * 0.1),
      bottomLeft: Radius.circular(size * 0.2),
      bottomRight: Radius.circular(size * 0.2),
    ));
    
    canvas.drawPath(cupPath, trophyPaint);

    // Trophy handles (left and right)
    var handlePaint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.08;

    // Left handle
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX - cupWidth * 0.6, centerY - size * 0.1),
        width: size * 0.4,
        height: size * 0.3,
      ),
      -math.pi / 2,
      math.pi,
      false,
      handlePaint,
    );

    // Right handle
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(centerX + cupWidth * 0.6, centerY - size * 0.1),
        width: size * 0.4,
        height: size * 0.3,
      ),
      -math.pi / 2,
      -math.pi,
      false,
      handlePaint,
    );

    // Trophy base
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(centerX, centerY + size * 0.35),
          width: cupWidth * 1.2,
          height: size * 0.2,
        ),
        topLeft: Radius.circular(size * 0.05),
        topRight: Radius.circular(size * 0.05),
        bottomLeft: Radius.circular(size * 0.05),
        bottomRight: Radius.circular(size * 0.05),
      ),
      trophyPaint,
    );

    // Trophy stem
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY + size * 0.25),
        width: size * 0.15,
        height: size * 0.2,
      ),
      trophyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Set to true if the properties of the painter can change,
    // causing a repaint (e.g., if `topRadius` was a dynamic variable).
    // For static shapes, false is efficient.
    return false;
  }
}
class StraightPentagonBadgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width;
    double height = size.height;

    // --- Paint for the Border ---
    var borderPaint = Paint()
      ..color = Colors.blue.shade700 // Deep blue border
      ..style = PaintingStyle.stroke // Draw only the border
      ..strokeWidth = 4.0; // Thickness of the border

    // --- Paint for the Inner Fill ---
    var fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.yellow.shade100, // Lighter yellow at the top
          Colors.yellow.shade300, // Slightly darker yellow at the bottom
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    // --- Pentagon Points (Straight edges only) ---
    var pentagonPath = Path();

    // Define the 5 points of the pentagon
    // 1. Top-left point
    Offset topLeft = Offset(0, height * 0.2);
    
    // 2. Top-right point
    Offset topRight = Offset(width, height * 0.2);
    
    // 3. Bottom-right point
    Offset bottomRight = Offset(width * 0.8, height * 0.8);
    
    // 4. Bottom center point (the sharp peak)
    Offset bottomCenter = Offset(width / 2, height);
    
    // 5. Bottom-left point
    Offset bottomLeft = Offset(width * 0.2, height * 0.8);

    // --- Drawing the Pentagon Path ---
    pentagonPath.moveTo(topLeft.dx, topLeft.dy);
    pentagonPath.lineTo(topRight.dx, topRight.dy);
    pentagonPath.lineTo(bottomRight.dx, bottomRight.dy);
    pentagonPath.lineTo(bottomCenter.dx, bottomCenter.dy);
    pentagonPath.lineTo(bottomLeft.dx, bottomLeft.dy);
    pentagonPath.close(); // Close the path back to the starting point

    // Draw the filled pentagon
    canvas.drawPath(pentagonPath, fillPaint);
    
    // Draw the border
    canvas.drawPath(pentagonPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Alternative version with adjustable parameters
class CustomStraightPentagonPainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;
  final double borderWidth;
  final double topWidth; // How wide the top should be (0.0 to 1.0)
  final double bottomWidth; // How wide the bottom should be (0.0 to 1.0)

  CustomStraightPentagonPainter({
    this.borderColor = Colors.blue,
    this.fillColor = Colors.yellow,
    this.borderWidth = 4.0,
    this.topWidth = 1.0, // Full width at top
    this.bottomWidth = 0.6, // 60% width at bottom
  });

  @override
  void paint(Canvas canvas, Size size) {
    double width = size.width;
    double height = size.height;

    // --- Paint for the Border ---
    var borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // --- Paint for the Inner Fill ---
    var fillPaint = Paint()..color = fillColor;

    // --- Pentagon Points with custom proportions ---
    var pentagonPath = Path();

    // Calculate the actual widths based on percentages
    double actualTopWidth = width * topWidth;
    double actualBottomWidth = width * bottomWidth;
    
    // Center the pentagon horizontally
    double topStartX = (width - actualTopWidth) / 2;
    double bottomStartX = (width - actualBottomWidth) / 2;

    // Define the 5 points of the pentagon
    Offset topLeft = Offset(topStartX, 0);
    Offset topRight = Offset(topStartX + actualTopWidth, 0);
    Offset bottomRight = Offset(bottomStartX + actualBottomWidth, height * 0.7);
    Offset bottomCenter = Offset(width / 2, height);
    Offset bottomLeft = Offset(bottomStartX, height * 0.7);

    // --- Drawing the Pentagon Path ---
    pentagonPath.moveTo(topLeft.dx, topLeft.dy);
    pentagonPath.lineTo(topRight.dx, topRight.dy);
    pentagonPath.lineTo(bottomRight.dx, bottomRight.dy);
    pentagonPath.lineTo(bottomCenter.dx, bottomCenter.dy);
    pentagonPath.lineTo(bottomLeft.dx, bottomLeft.dy);
    pentagonPath.close();

    // Draw the filled pentagon
    canvas.drawPath(pentagonPath, fillPaint);
    
    // Draw the border
    canvas.drawPath(pentagonPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// Usage example widget
class PentagonBadge extends StatelessWidget {
  final double width;
  final double height;
  final Color? borderColor;
  final Color? fillColor;
  final double? borderWidth;

  const PentagonBadge({
    Key? key,
    this.width = 100,
    this.height = 120,
    this.borderColor,
    this.fillColor,
    this.borderWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: CustomStraightPentagonPainter(
        borderColor: borderColor ?? Colors.blue.shade700,
        fillColor: fillColor ?? Colors.yellow.shade200,
        borderWidth: borderWidth ?? 4.0,
      ),
    );
  }
}