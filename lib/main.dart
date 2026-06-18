import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/service_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/pet_screen.dart';
import 'screens/profile_screen.dart';

import 'package:provider/provider.dart';
import 'providers/pet_provider.dart';

void main() {
  runApp(const PawlyApp());
}

class PawlyApp extends StatelessWidget {
  const PawlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pawly",
      debugShowCheckedModeBanner: false,
      // 1. Global Brand Theme
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9800),
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFF26A69A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
        // FIXED: Changed CardTheme to CardThemeData
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final pages = const [
    HomeScreen(),
    ServiceScreen(),
    TrackerScreen(), // Future: Replace with dedicated Tracker Screen
    PetScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
      // 2. Updated Bottom Navigation Strategy
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        indicatorColor: const Color(0xFFFF9800).withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFFF9800)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store, color: Color(0xFFFF9800)),
            label: 'Book', // Changed from "Services" for a clearer call-to-action
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart, color: Color(0xFFFF9800)),
            label: 'Tracker', // Shifted focus from "Community" to "Tracker"
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets, color: Color(0xFFFF9800)),
            label: 'My Pets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF9800)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}