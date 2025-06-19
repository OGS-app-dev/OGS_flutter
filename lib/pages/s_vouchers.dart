import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/pages/comingsoon.dart';
import 'package:ogs/services/points_service.dart';
import 'package:ogs/models/voucher.dart';
import 'package:ogs/models/user_points.dart';
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
  List<Voucher> availableVouchers = [];
  UserPoints? userPoints;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        currentUserId = user.uid;
        
        // Load user points and available vouchers simultaneously
        final results = await Future.wait([
          PointsService.getUserPoints(user.uid),
          PointsService.getAvailableVouchers(),
        ]);

        setState(() {
          userPoints = results[0] as UserPoints?;
          availableVouchers = results[1] as List<Voucher>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading voucher data: $e');
      setState(() {
        isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vouchers. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _redeemVoucher(Voucher voucher) async {
    if (currentUserId == null) {
      _showMessage('Please log in to redeem vouchers', isError: true);
      return;
    }

    if (userPoints == null || userPoints!.totalPoints < voucher.pointsCost) {
      _showMessage(
        'Insufficient points! You need ${voucher.pointsCost} points but have ${userPoints?.totalPoints ?? 0}.',
        isError: true,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showRedeemConfirmation(voucher);
    if (!confirmed) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await PointsService.redeemVoucher(currentUserId!, voucher.id);
      Navigator.pop(context); // Close loading dialog

      if (success) {
        _showMessage('🎉 Voucher redeemed successfully!', isError: false);
        
        // Refresh data to show updated points
        await _initializeData();
        
        // Navigate to user vouchers or show success screen
        _showRedemptionSuccess(voucher);
      } else {
        _showMessage('Failed to redeem voucher. Please try again.', isError: true);
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showMessage('An error occurred. Please try again.', isError: true);
    }
  }

  Future<bool> _showRedeemConfirmation(Voucher voucher) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to redeem this voucher?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    voucher.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(voucher.description),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cost: ${voucher.pointsCost} points'),
                      Text('Your Points: ${userPoints?.totalPoints ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showRedemptionSuccess(Voucher voucher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Success!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have successfully redeemed:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    voucher.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    voucher.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Check "My Vouchers" section to view and use your redeemed vouchers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

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
                right: 20,
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
                    const Expanded(
                      child: Text(
                        'Vouchers',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                    // Points display
                    if (userPoints != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${userPoints!.totalPoints}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
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
          const SizedBox(height: 25),
          
          // Loading or content
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading vouchers...'),
                      ],
                    ),
                  )
                : availableVouchers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _initializeData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: availableVouchers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildVoucherCard(availableVouchers[index]),
                            );
                          },
                        ),
                      ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No vouchers available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new offers!',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    // Determine card colors based on voucher type or use defaults
    List<Color> cardColors;
    IconData categoryIcon;
    
    switch (voucher.category?.toLowerCase()) {
      case 'movie':
      case 'entertainment':
        cardColors = [const Color(0xFF6A5ACD), const Color(0xFF483D8B)];
        categoryIcon = Icons.movie;
        break;
      case 'restaurant':
      case 'food':
        cardColors = [const Color(0xFFFF6347), const Color(0xFFDC143C)];
        categoryIcon = Icons.restaurant;
        break;
      case 'fashion':
      case 'shopping':
        cardColors = [const Color(0xFFFF1493), const Color(0xFFDC143C)];
        categoryIcon = Icons.shopping_bag;
        break;
      case 'cashback':
        cardColors = [const Color(0xFFFFD700), const Color(0xFFFFA500)];
        categoryIcon = Icons.account_balance_wallet;
        break;
      default:
        cardColors = [const Color(0xFF32CD32), const Color(0xFF228B22)];
        categoryIcon = Icons.local_offer;
    }

    final canAfford = userPoints != null && userPoints!.totalPoints >= voucher.pointsCost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: CustomTicketWidget(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 160,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: cardColors,
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

              // Points cost badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.stars,
                        size: 14,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${voucher.pointsCost}',
                        style: TextStyle(
                          color: cardColors[0],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                      child: Icon(
                        categoryIcon,
                        color: cardColors[0],
                        size: 30,
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
                            voucher.title,
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
                            voucher.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: canAfford ? Colors.white : Colors.white.withOpacity(0.7),
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
                                backgroundColor: canAfford ? Colors.white : Colors.white.withOpacity(0.7),
                                foregroundColor: canAfford ? cardColors[0] : Colors.grey,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24, 
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: canAfford ? () => _redeemVoucher(voucher) : null,
                              child: Text(
                                canAfford ? 'Redeem Now' : 'Not Enough Points',
                                style: const TextStyle(
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