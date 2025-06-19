// services/screen_time_tracker.dart
import 'package:flutter/material.dart';
import 'package:ogs/models/user_points.dart';
import 'package:ogs/services/points_service.dart';

class ScreenTimeTracker extends WidgetsBindingObserver {
  static final ScreenTimeTracker _instance = ScreenTimeTracker._internal();
  factory ScreenTimeTracker() => _instance;
  ScreenTimeTracker._internal();
  
  DateTime? _appStartTime;
  String? _userId;
  bool _isTracking = false;
  
  void initialize(String userId) {
    _userId = userId;
    WidgetsBinding.instance.addObserver(this);
    _startTracking();
  }
  
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTracking();
  }
  
  void _startTracking() {
    _appStartTime = DateTime.now();
    _isTracking = true;
  }
  
  void _stopTracking() {
    if (_isTracking && _appStartTime != null && _userId != null) {
      final sessionMinutes = DateTime.now().difference(_appStartTime!).inMinutes;
      if (sessionMinutes > 0) {
        PointsService.trackScreenTime(_userId!, sessionMinutes);
      }
    }
    _isTracking = false;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopTracking();
        break;
      default:
        break;
    }
  }
}

// widgets/points_popup.dart
class PointsPopup extends StatefulWidget {
  final int points;
  final String description;
  final VoidCallback? onClose;

  const PointsPopup({
    Key? key,
    required this.points,
    required this.description,
    this.onClose,
  }) : super(key: key);

  @override
  State<PointsPopup> createState() => _PointsPopupState();
}

class _PointsPopupState extends State<PointsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.forward();
    
    // Auto close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _close();
      }
    });
  }

  void _close() {
    _controller.reverse().then((_) {
      if (widget.onClose != null) {
        widget.onClose!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFDA45),
                    const Color(0xFFFFB347),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '+${widget.points} Points!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Awesome!',
                        style: TextStyle(
                          color: Color(0xFFFFDA45),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper function to show points popup
class PointsHelper {
  static OverlayEntry? _currentOverlay;
  
  static void showPointsPopup(
    BuildContext context,
    int points,
    String description,
  ) {
    // Remove existing overlay if any
    _currentOverlay?.remove();
    
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.3,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: PointsPopup(
            points: points,
            description: description,
            onClose: () {
              _currentOverlay?.remove();
              _currentOverlay = null;
            },
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_currentOverlay!);
  }
}