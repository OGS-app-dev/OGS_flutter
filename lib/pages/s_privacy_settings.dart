import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ogs/constants.dart';

enum ProtectionLevel { standard, high, manual }

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  ProtectionLevel _selectedProtection = ProtectionLevel.standard;
  bool _isLoading = true;

  // Privacy settings for manual mode
  Map<String, bool> _privacySettings = {
    'blockTrackers': true,
    'blockAds': true,
    'blockCookies': false,
    'blockScripts': false,
    'httpsOnly': true,
    'clearDataOnExit': false,
    'incognitoMode': false,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Load protection level
      final protectionIndex = prefs.getInt('protection_level') ?? 0;
      _selectedProtection = ProtectionLevel.values[protectionIndex];

      // Load individual privacy settings
      _privacySettings = {
        'blockTrackers': prefs.getBool('blockTrackers') ?? true,
        'blockAds': prefs.getBool('blockAds') ?? true,
        'blockCookies': prefs.getBool('blockCookies') ?? false,
        'blockScripts': prefs.getBool('blockScripts') ?? false,
        'httpsOnly': prefs.getBool('httpsOnly') ?? true,
        'clearDataOnExit': prefs.getBool('clearDataOnExit') ?? false,
        'incognitoMode': prefs.getBool('incognitoMode') ?? false,
      };

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Save protection level
    await prefs.setInt('protection_level', _selectedProtection.index);

    // Save individual privacy settings
    for (final entry in _privacySettings.entries) {
      await prefs.setBool(entry.key, entry.value);
    }

    _showSnackBar('Settings saved successfully');
  }

  void _applyProtectionLevel(ProtectionLevel level) {
    setState(() {
      _selectedProtection = level;

      switch (level) {
        case ProtectionLevel.standard:
          _privacySettings = {
            'blockTrackers': true,
            'blockAds': true,
            'blockCookies': false,
            'blockScripts': false,
            'httpsOnly': true,
            'clearDataOnExit': false,
            'incognitoMode': false,
          };
          break;

        case ProtectionLevel.high:
          _privacySettings = {
            'blockTrackers': true,
            'blockAds': true,
            'blockCookies': true,
            'blockScripts': true,
            'httpsOnly': true,
            'clearDataOnExit': true,
            'incognitoMode': false,
          };
          break;

        case ProtectionLevel.manual:
          // Keep current settings, user will configure manually
          break;
      }
    });

    _saveSettings();
  }

  void _showManualSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildManualSettingsSheet(),
    );
  }

  Widget _buildManualSettingsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Manual Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _saveSettings();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),

          // Settings list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSettingTile(
                  'Block Trackers',
                  'Prevent websites from tracking your activity',
                  Icons.shield_outlined,
                  'blockTrackers',
                ),
                _buildSettingTile(
                  'Block Ads',
                  'Block advertisements and pop-ups',
                  Icons.block,
                  'blockAds',
                ),
                _buildSettingTile(
                  'Block Cookies',
                  'Prevent websites from storing cookies',
                  Icons.cookie_outlined,
                  'blockCookies',
                ),
                _buildSettingTile(
                  'Block Scripts',
                  'Block JavaScript and other scripts',
                  Icons.code_off,
                  'blockScripts',
                ),
                _buildSettingTile(
                  'HTTPS Only',
                  'Force secure connections when available',
                  Icons.lock_outline,
                  'httpsOnly',
                ),
                _buildSettingTile(
                  'Clear Data on Exit',
                  'Automatically clear browsing data when closing',
                  Icons.delete_sweep,
                  'clearDataOnExit',
                ),
                _buildSettingTile(
                  'Enhanced Privacy Mode',
                  'Additional privacy protections',
                  Icons.privacy_tip_outlined,
                  'incognitoMode',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
      String title, String subtitle, IconData icon, String key) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: Switch(
        value: _privacySettings[key] ?? false,
        onChanged: (value) {
          setState(() {
            _privacySettings[key] = value;
          });
        },
        activeColor: yel,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildProtectionOption({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required ProtectionLevel level,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedProtection == level;

    return GestureDetector(
      onTap: onTap ?? () => _applyProtectionLevel(level),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<ProtectionLevel>(
              value: level,
              groupValue: _selectedProtection,
              onChanged: (value) => _applyProtectionLevel(value!),
              activeColor: const Color.fromARGB(255, 0, 0, 0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          // Header with curved background
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
                      'Privacy & Settings',
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Standard Protection
                  _buildProtectionOption(
                    title: 'Standard Protection',
                    description:
                        '(Recommended) Block web features with minimal impact to how Pages behave',
                    icon: Icons.shield_outlined,
                    iconColor: Colors.blue,
                    level: ProtectionLevel.standard,
                  ),
                  Divider(
                    color: const Color.fromARGB(255, 210, 210, 210),
                    thickness: 0.6,
                    height: 8,
                  ),

                  // High Protection
                  _buildProtectionOption(
                    title: 'High Protection',
                    description: 'Block web features that are often Dangerous',
                    icon: Icons.security,
                    iconColor: Colors.orange,
                    level: ProtectionLevel.high,
                  ),
                 Divider(
                    color: const Color.fromARGB(255, 210, 210, 210),
                    thickness: 0.6,
                    height: 8,
                  ),
                  // Manual
                  _buildProtectionOption(
                    title: 'Manual',
                    description: 'Add and remove all settings yourself',
                    icon: Icons.settings,
                    iconColor: Colors.grey,
                    level: ProtectionLevel.manual,
                    onTap: () {
                      _applyProtectionLevel(ProtectionLevel.manual);
                      _showManualSettings();
                    },
                  ),
                  Divider(
                    color: const Color.fromARGB(255, 210, 210, 210),
                    thickness: 0.6,
                    height: 8,
                  ),

                  const SizedBox(height: 40),
                ],
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
    var paintBlue = Paint()..color = pricol;
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
