import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ogs/services/points_service.dart';
import 'package:ogs/models/voucher.dart';
import 'package:ogs/models/user_points.dart';
import 'package:url_launcher/url_launcher.dart';

class VouchersScreen extends StatefulWidget {
  const VouchersScreen({
    super.key,
  });

  @override
  
  State<VouchersScreen> createState() => _VouchersScreenState();
}

class _VouchersScreenState extends State<VouchersScreen> {
  List<VoucherWithStatus> vouchersWithStatus = [];
  UserPoints? userPoints;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
  print('🔄 Starting _initializeData');

  if (!mounted) return;

  setState(() => isLoading = true);

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ No user logged in');
      return;
    }

    currentUserId = user.uid;
    print('👤 User ID: $currentUserId');

    // Fetch one by one (no Future.wait)
    final userPointsData = await PointsService.getUserPoints(user.uid);
    final vouchersData = await PointsService.getAvailableVouchersWithStatus(user.uid);

    if (!mounted) return;

    print('✅ Loaded userPoints: $userPointsData');
    print('✅ Loaded vouchers: ${vouchersData.length} items');

    setState(() {
      userPoints = userPointsData;
      vouchersWithStatus = vouchersData;
    });
  } catch (e, st) {
    print('❌ Error loading data: $e');
    print(st);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      print('✅ Finished _initializeData');
    }
  }
}

  // In _redeemVoucher
Future<void> _redeemVoucher(VoucherWithStatus voucherWithStatus) async {
  // ... (previous code)

  try {
    final result = await PointsService.redeemVoucherWithCode(
      currentUserId!,
      voucherWithStatus.userVoucher!.id!,
      voucherWithStatus.voucher.redeemCode!,
    );

    _closeLoadingDialog();

    if (result.success) {
      // Pass isError: false for success
      _showMessage('Success!',  isError: false, );
      await _initializeData();
    } else {
      // Pass isError: true for failure
      _showMessage('Redeem Failed',isError: true, );
    }
  } catch (e) {
    _closeLoadingDialog();
    // This looks like it was _showErrorSnackBar previously, ensure it's _showMessage now if you unified
    _showMessage('Error', isError: true, );
  }
}

// In _unlockVoucher
Future<void> _unlockVoucher(VoucherWithStatus voucherWithStatus) async {
  // ... (previous code)

  try {
    final result = await PointsService.unlockVoucherWithPoints(
      currentUserId!,
      voucherWithStatus.voucher.id!,
    );

    _closeLoadingDialog();

    if (result.success) {
      // Pass isError: false for success
      _showMessage('Success!',  isError: false);
      await _initializeData();
    } else {
      // Pass isError: true for failure
      _showMessage('Unlock Failed', isError: true);
    }
  } catch (e) {
    _closeLoadingDialog();
    // This looks like it was _showErrorSnackBar previously, ensure it's _showMessage now if you unified
    _showMessage('Error', isError: true,);
  }
}

// And also ensure your _showErrorSnackBar uses isError: true if you still have it
// or just replace _showErrorSnackBar calls with _showMessage directly.
void _showErrorSnackBar(String message) {
  _showMessage(message, isError: true,);
}
void _markVoucherAsUnlocked(String voucherId, UserVoucher userVoucher) {
  final index = vouchersWithStatus.indexWhere((v) => v.voucher.id == voucherId);
  if (index != -1) {
    setState(() {
      vouchersWithStatus[index] = vouchersWithStatus[index].copyWith(
        isUnlocked: true,
        userVoucher: userVoucher,
      );
      userPoints = userPoints?.copyWith(
        totalPoints: userPoints!.totalPoints - vouchersWithStatus[index].voucher.pointsCost,
      );
    });
  }
}

void _markVoucherAsUsed(String userVoucherId) {
  final index = vouchersWithStatus.indexWhere(
    (v) => v.userVoucher?.id == userVoucherId,
  );
  if (index != -1) {
    setState(() {
      vouchersWithStatus[index] = vouchersWithStatus[index].copyWith(
        isUsed: true,
      );
    });
  }
}


Future<void> _refreshVoucherData() async {
  if (!mounted) return;

  setState(() => isLoading = true);
 // await _initializeData();
}


void _showLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );
}


void _closeLoadingDialog() {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop(); // Close loading
  }
}


  Future<void> _redirectToWebsite(String url, Voucher voucher) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show message that they've been redirected
        if (mounted) {
          _showMessage('Redirected to ${voucher.title} website', isError: false);
        }
      } else {
        if (mounted) {
          _showMessage('Could not open website. Please try again later.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Invalid website URL', isError: true);
      }
    }
  }

  Future<bool> _showUnlockConfirmation(Voucher voucher) async {
    if (!mounted) return false;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to unlock this voucher?'),
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
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  Future<String?> _showRedeemCodeDialog(Voucher voucher) async {
    if (!mounted) return null;
    
    final TextEditingController codeController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Redemption Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the redemption code for:'),
            const SizedBox(height: 8),
            Text(
              voucher.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Redemption Code',
                hintText: 'Enter code here',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, codeController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    
    return result;
  }

  void _showUnlockSuccess(Voucher voucher) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Unlocked!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You have successfully unlocked:'),
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
              'You can now redeem this voucher using the redeem button!',
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

  void _showRedemptionSuccess(Voucher voucher) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Redeemed!'),
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
              'Your voucher has been successfully redeemed!',
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
            child: const Text('Awesome!'),
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
                : vouchersWithStatus.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _initializeData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: vouchersWithStatus.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: _buildVoucherCard(vouchersWithStatus[index]),
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

  Widget _buildVoucherCard(VoucherWithStatus voucherWithStatus) {
    final voucher = voucherWithStatus.voucher;
    
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
    final canUnlock = voucherWithStatus.canUnlock && canAfford;
    final canRedeem = voucherWithStatus.canRedeem;
    final isUsed = voucherWithStatus.isUsed;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: CustomTicketWidget(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 160,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUsed 
                  ? [Colors.grey.shade400, Colors.grey.shade600] 
                  : cardColors,
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

              // Status badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUsed 
                        ? Colors.grey.shade300 
                        : voucherWithStatus.isUnlocked 
                            ? Colors.green.shade100 
                            : Colors.white,
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
                      if (isUsed)
                        const Icon(Icons.check_circle, size: 14, color: Colors.grey)
                      else if (voucherWithStatus.isUnlocked)
                        const Icon(Icons.lock_open, size: 14, color: Colors.green)
                      else
                        const Icon(Icons.stars, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        isUsed 
                            ? 'Used' 
                            : voucherWithStatus.isUnlocked 
                                ? 'Unlocked' 
                                : '${voucher.pointsCost}',
                        style: TextStyle(
                          color: isUsed 
                              ? Colors.grey.shade600 
                              : voucherWithStatus.isUnlocked 
                                  ? Colors.green.shade700 
                                  : cardColors[0],
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
                        color: isUsed ? Colors.grey.shade600 : cardColors[0],
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              decoration: isUsed ? TextDecoration.lineThrough : null,
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
                              color: _getButtonColor(voucherWithStatus, canAfford),
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
                                backgroundColor: _getButtonColor(voucherWithStatus, canAfford),
                                foregroundColor: _getButtonTextColor(voucherWithStatus, canAfford, cardColors[0]),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24, 
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: _getButtonAction(voucherWithStatus, canAfford),
                              child: Text(
                                _getButtonText(voucherWithStatus, canAfford),
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

  Color _getButtonColor(VoucherWithStatus voucherWithStatus, bool canAfford) {
    if (voucherWithStatus.isUsed) return Colors.grey.shade300;
    if (voucherWithStatus.canRedeem) return Colors.green.shade100;
    if (voucherWithStatus.canUnlock && canAfford) return Colors.white;
    return Colors.white.withOpacity(0.7);
  }

  Color _getButtonTextColor(VoucherWithStatus voucherWithStatus, bool canAfford, Color cardColor) {
    if (voucherWithStatus.isUsed) return Colors.grey.shade600;
    if (voucherWithStatus.canRedeem) return Colors.green.shade700;
    if (voucherWithStatus.canUnlock && canAfford) return cardColor;
    return Colors.grey;
  }

  String _getButtonText(VoucherWithStatus voucherWithStatus, bool canAfford) {
    if (voucherWithStatus.isUsed) return 'Used';
    if (voucherWithStatus.canRedeem) return 'Redeem Now';
    if (voucherWithStatus.canUnlock && canAfford) return 'Unlock';
    if (voucherWithStatus.canUnlock && !canAfford) return 'Not Enough Points';
    return 'Unlocked';
  }

  VoidCallback? _getButtonAction(VoucherWithStatus voucherWithStatus, bool canAfford) {
    if (voucherWithStatus.isUsed) return null;
    if (voucherWithStatus.canRedeem) return () => _redeemVoucher(voucherWithStatus);
    if (voucherWithStatus.canUnlock && canAfford) return () => _unlockVoucher(voucherWithStatus);
    return null;
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
