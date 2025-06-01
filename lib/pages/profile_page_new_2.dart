import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color:const  Color.fromARGB(0, 3, 3, 1),
            child: Column(
              children: [
                CustomPaint(
                  painter: CurvePainter(),
                  child: Container(
                    color:const  Color.fromARGB(0, 3, 3, 1),
                    height: 200, 
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 65, 
            left: 0,
            right: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const  Text(
                  'Profile',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color:  Color.fromARGB(255, 0, 0, 0)),
                ),
              const  SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient:const LinearGradient(
                      colors: [Color(0xFFFFE57D), Color(0xFFFFCC00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset:const Offset(0, 3), 
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromARGB(255, 255, 255, 255), 
                            width: 5.0,
                          ),
                        ),
                        child:const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage(
                              'lib/assets/images/placeholder_profile.png'),
                        ),
                      ),
                     const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const  Text(
                            'User',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '9398894122',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    const  Spacer(),
                    const  Text(
                        'Edit',
                        style:  TextStyle(
                            color:  Color.fromARGB(255, 0, 0, 0),
                            fontSize: 16),
                      ),
                     const Icon(Icons.edit,
                          color:  Color.fromARGB(255, 0, 0, 0), size: 16),
                    ],
                  ),
                ),
               const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFeatureItem(Icons.star, 'Points'),
                    _buildFeatureItem(Icons.card_giftcard, 'Voucher'),
                    _buildFeatureItem(Icons.thumb_up, 'Rating'),
                  ],
                ),
              const  SizedBox(height: 30),
                _buildMenuItem(Icons.info_outline, 'About us'),
                _buildMenuItem(Icons.settings, 'Settings'),
                _buildMenuItem(Icons.feedback, 'Send Feedback'),
                _buildMenuItem(Icons.report, 'Report'),
                _buildMenuItem(Icons.notifications, 'Notifications'),
                _buildMenuItem(Icons.logout, 'Log out'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.grey[700]),
       const SizedBox(height: 5),
        Text(text, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
        const  SizedBox(width: 15),
          Text(text, style: const TextStyle(fontSize: 18)),
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
    pathBlue.lineTo(0, size.height * 1); 
    pathBlue.quadraticBezierTo(size.width / 2, size.height, size.width, size.height * 1); // Deeper curve
    pathBlue.lineTo(size.width, 0);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);
     var paintYellow = Paint()..color = Colors.yellow.shade700;
    var pathYellow = Path();
    pathYellow.lineTo(0, size.height * 0.7);
    pathYellow.quadraticBezierTo(size.width / 2, size.height * 0.9, size.width, size.height * 0.5);
    pathYellow.lineTo(size.width, 0);
    pathYellow.close();
    canvas.drawPath(pathYellow, paintYellow);
    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
