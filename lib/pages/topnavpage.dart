import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:line_icons/line_icons.dart';
import 'package:ogs/constants.dart';
import 'package:ogs/pages/bus_position.dart';

class TopTabPage extends StatefulWidget {
  const TopTabPage({super.key});

  @override
  State<TopTabPage> createState() => _TopTabPageState();
}

class _TopTabPageState extends State<TopTabPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // length matches your number of tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: pricol, // Your primary color for the app bar
        title: Text(
          'Bus Tracking',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: yel, // Your yellow accent color for the indicator
          labelColor: Colors.yellow, // Color for selected tab's text/icon
          unselectedLabelColor: Colors.white.withOpacity(0.7), // Color for unselected tabs
          labelStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          isScrollable: false, // Set to true if you have many tabs
          tabs: const [
            Tab(text: 'LH 1', icon: Icon(LineIcons.bus)),
            Tab(text: 'LH 2', icon: Icon(LineIcons.bus)),
            Tab(text: 'MBH 1', icon: Icon(LineIcons.bus)),
            Tab(text: 'MBH 2', icon: Icon(LineIcons.bus)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BusPosition(busId: 'lh_1'),
          BusPosition(busId: 'lh_2'),
          BusPosition(busId: 'mbh_1'),
          BusPosition(busId: 'mbh_2'),
        ],
      ),
    );
  }
}