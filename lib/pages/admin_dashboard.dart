import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/admin_hotel.dart';
import 'package:ogs/pages/admin_hsptl.dart';
import 'package:ogs/pages/admin_movies.dart';
import 'package:ogs/pages/admin_petrol.dart';
import 'package:ogs/pages/admin_restaurants.dart';
import 'package:ogs/pages/admin_events.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String adminName = "Admin";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              yel, 
              Colors.white, 
            ],
          ),
        ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome back,",
                        style: TextStyle(
                          color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        adminName,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Text(
                      adminName.split(' ').map((e) => e[0]).join().toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildNavigationCard(
                    icon: Icons.hotel,
                    title: "Hotels",
                    subtitle: "Add Hotels",
                    color: Colors.green,
                    onTap: () => _navigateToPage(context, "Hotels"),
                  ),
                  _buildNavigationCard(
                    icon: Icons.local_hospital,
                    title: "Hospitals",
                    subtitle: "Add Hospital",
                    color: Colors.orange,
                    onTap: () => _navigateToPage(context, "Hospitals"),
                  ),
                  _buildNavigationCard(
                    icon: Icons.movie,
                    title: "Movies",
                    subtitle: "Add Movies",
                    color: Colors.purple,
                    onTap: () => _navigateToPage(context, "Movies"),
                  ),
                  _buildNavigationCard(
                    icon: Icons.event,
                    title: "Events",
                    subtitle: "Add Events/URL",
                    color: Colors.blue,
                    onTap: () => _navigateToPage(context, "Events"),
                  ),
                  _buildNavigationCard(
                    icon: Icons.local_gas_station,
                    title: "Petrol Pumbs",
                    subtitle: "Add Petrol Pumbs",
                    color: Colors.grey,
                    onTap: () => _navigateToPage(context, "Petrol"),
                  ),
                  _buildNavigationCard(
                    icon: Icons.restaurant,
                    title: "Restaurants",
                    subtitle: "Add Restaurants",
                    color: Colors.red,
                    onTap: () => _navigateToPage(context, "Restaurants"),
                  ),
                  _buildNavigationCard(
                    icon: Icons.campaign,
                    title: "Advertisements",
                    subtitle: "Manage Ads",
                    color: Colors.indigo,
                    onTap: () => _navigateToPage(context, "Advertisements"),
                  ),
                  _buildNavigationCard(
                    icon: Icons.account_balance,
                    title: "Banks",
                    subtitle: "Manage Banks",
                    color: const Color.fromARGB(255, 235, 59, 226),
                    onTap: () => _navigateToPage(context, "Banks"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String pageName) {
    Widget page;
    
    switch (pageName) {
      case "Hotels":
        page = const HotelAdminDashboard();
        break;
      case "Hospitals":
        page = const HospitalAdminDashboard();
        break;
      case "Movies":
        page = const MovieAdminDashboard();
        break;
      case "Petrol":
        page = const PetrolAdminDashboard();
        break;
      case "Restaurants":
        page = const RestaurantAdminDashboard();
        break;
      case "Events":
        page = const EventAdminDashboard();
        break;
      case "Advertisements":
        page = PlaceholderPage(pageName: "Advertisements");
        break;
      case "Banks":
        page = PlaceholderPage(pageName: "Banks");
        break;
      default:
        page = PlaceholderPage(pageName: pageName);
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String pageName;

  const PlaceholderPage({super.key, required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageName),
        backgroundColor: pricol,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "$pageName Page",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "This page is under construction",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}