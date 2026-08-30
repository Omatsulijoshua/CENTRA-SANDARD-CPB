import 'package:central_stadard_cpb/pages/activity.dart';
import 'package:central_stadard_cpb/pages/my_card.dart';
import 'package:central_stadard_cpb/pages/profile.dart';
import 'package:central_stadard_cpb/pages/scan.dart';
import 'package:central_stadard_cpb/pages/home.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const Home(),
    const MyCard(),
    const ScanPage(),
    const ActivityPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            tabItem(Icons.home, "Home", 0),
            tabItem(Icons.credit_card, "My Card", 1),

            // FAB
            FloatingActionButton(
              onPressed: () => onTabTapped(2),
              backgroundColor: const Color.fromARGB(255, 16, 80, 98),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            ),

            tabItem(Icons.bar_chart, "Activity", 3),
            tabItem(Icons.person, "Profile", 4),
          ],
        ),
      ),
    );
  }

  Widget tabItem(IconData icon, String label, int index) {
    return IconButton(
      onPressed: () => onTabTapped(index),
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: currentIndex == index
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: currentIndex == index
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }
}
