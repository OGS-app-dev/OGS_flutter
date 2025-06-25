import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateUsManager {
  static const String _launchCountKey = 'launch_count';
  static const String _ratedKey = 'user_rated';
  static const String _dontShowAgainKey = 'dont_show_again';
  
  static Future<void> checkAndShowRateDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if user already rated or chose "Don't show again"
    bool hasRated = prefs.getBool(_ratedKey) ?? false;
    bool dontShowAgain = prefs.getBool(_dontShowAgainKey) ?? false;
    
    if (hasRated || dontShowAgain) return;
    
    // Increment launch count
    int launchCount = prefs.getInt(_launchCountKey) ?? 0;
    launchCount++;
    await prefs.setInt(_launchCountKey, launchCount);
    
    // Show rate dialog after 3 launches, then every 10 launches
    if (launchCount == 1 || (launchCount > 1 && launchCount % 10 == 0)) {
      _showRateDialog(context);
    }
  }
  
  static void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate Our App'),
          content: const Text(
            'If you enjoy using our app, would you mind taking a moment to rate it? Thanks for your support!',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool(_dontShowAgainKey, true);
              },
              child: const Text('No Thanks'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Ask again later (reset launch count)
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(_launchCountKey, 0);
              },
              child: const Text('Maybe Later'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _rateApp();
              },
              child: const Text('Rate Now'),
            ),
          ],
        );
      },
    );
  }
  
  static Future<void> _rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    final prefs = await SharedPreferences.getInstance();
    
    if (await inAppReview.isAvailable()) {
      // Show native in-app review dialog
      inAppReview.requestReview();
    } else {
      // Fallback to opening store
      inAppReview.openStoreListing();
    }
    
    // Mark as rated
    await prefs.setBool(_ratedKey, true);
  }
  
  // Method to manually trigger rate dialog (e.g., from settings)
  static void showRateDialogManually(BuildContext context) {
    _showRateDialog(context);
  }
}


class RateUsWrapper extends StatefulWidget {
  final Widget child;
  final bool autoTrigger;
  
  const RateUsWrapper({
    Key? key,
    required this.child,
    this.autoTrigger = true,
  }) : super(key: key);
  
  @override
  State<RateUsWrapper> createState() => _RateUsWrapperState();
}

class _RateUsWrapperState extends State<RateUsWrapper> {
  @override
  void initState() {
    super.initState();
    if (widget.autoTrigger) {
      // Check for rate dialog when widget is initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        RateUsManager.checkAndShowRateDialog(context);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
