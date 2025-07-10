import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/services/points_service.dart';
import 'package:ogs/models/user_points.dart';

class PointsScreen extends StatefulWidget {
  @override
  _PointsScreenState createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  UserPoints? userPoints;
  bool isLoading = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    _loadUserPoints();
  }
  
  Future<void> _loadUserPoints() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final points = await PointsService.getUserPoints(user.uid);
        setState(() {
          userPoints = points;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to load points: $e';
        isLoading = false;
      });
    }
  }
  
  Future<void> _refreshPoints() async {
    await _loadUserPoints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: RefreshIndicator(
        onRefresh: _refreshPoints,
        child: Column(
          children: [
            Stack(
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
            SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 15,),
                      // Main Points Badge
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: const Color.fromARGB(255, 255, 252, 252),
                        child: isLoading 
                          ? _buildLoadingBadge()
                          : error != null 
                            ? _buildErrorBadge()
                            : CustomPaint(
                                size: const Size(350, 250), 
                                painter: PentagonBadgePainter(
                                  points: userPoints?.totalPoints ?? 0,
                                ),
                              ),
                      ),
                      
                      // // Points Summary Cards
                      // if (!isLoading && userPoints != null) ...[
                      //   Padding(
                      //     padding: const EdgeInsets.all(20),
                      //     child: Column(
                      //       children: [
                      //         _buildSummaryCard(),
                      //         SizedBox(height: 20),
                      //         _buildRecentTransactions(),
                      //       ],
                      //     ),
                      //   ),
                      // ],
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingBadge() {
    return Container(
      width: 350,
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade900),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your points...',
              style: TextStyle(
                color: Colors.indigo.shade900,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorBadge() {
    return Container(
      width: 350,
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade600,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load points',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refreshPoints,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade900,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Points Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade900,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total Points', '${userPoints!.totalPoints}', Icons.stars),
                _buildStatItem('Screen Time', '${userPoints!.screenTimeMinutes}m', Icons.access_time),
                _buildStatItem('Transactions', '${userPoints!.transactions.length}', Icons.receipt_long),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber.shade600, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecentTransactions() {
    final recentTransactions = userPoints!.transactions.take(5).toList();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade900,
                  ),
                ),
                Icon(Icons.history, color: Colors.grey.shade600),
              ],
            ),
            SizedBox(height: 12),
            if (recentTransactions.isEmpty)
              Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...recentTransactions.map((transaction) => _buildTransactionItem(transaction)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionItem(PointTransaction transaction) {
    final isPositive = transaction.points > 0;
    final icon = _getTransactionIcon(transaction.type);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDate(transaction.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${transaction.points}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPositive ? Colors.green.shade600 : Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'signup_bonus':
        return Icons.celebration;
      case 'daily_login':
        return Icons.login;
      case 'screen_time':
        return Icons.access_time;
      case 'facility_view':
        return Icons.visibility;
      case 'search':
        return Icons.search;
      case 'voucher_redeemed':
        return Icons.redeem;
      default:
        return Icons.stars;
    }
  }
  
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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
  }
}

class PentagonBadgePainter extends CustomPainter {
  final int points;
  
  PentagonBadgePainter({this.points = 0});

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

    // --- Draw Number Text (Dynamic Points) ---
    final textPainterNumber = TextPainter(
      text: TextSpan(
        text: '$points',
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
   // _drawYellowWings(canvas, width, height);

    // --- Draw Points Text ---
    final textPainterPoints = TextPainter(
      text: const TextSpan(
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PentagonBadgePainter) {
      return oldDelegate.points != points;
    }
    return true;
  }
}