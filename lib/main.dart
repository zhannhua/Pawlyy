import 'package:flutter/material.dart';
import 'dart:ui'; // Required for the Frosted Glass blur effect!

import 'screens/home_screen.dart';
import 'screens/service_screen.dart';
import 'screens/tracker_screen.dart';
import 'screens/pet_screen.dart';
import 'screens/profile_screen.dart';

import 'package:provider/provider.dart';
import 'providers/pet_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => PetProvider(),
      child: const PawlyApp(),
    ),
  );
}

class PawlyApp extends StatelessWidget {
  const PawlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Pawly",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9800),
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFF26A69A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
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
    TrackerScreen(),
    PetScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true, // CRITICAL: This allows the page to scroll BEHIND the frosted glass bar!
      body: pages[currentIndex],

      // Enriched Apple-Style Frosted Glass Navigation Bar
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Apple-style heavy blur
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85), // Semi-transparent
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
                    _buildNavItem(Icons.store_outlined, Icons.store, 'Book', 1),
                    _buildNavItem(Icons.monitor_heart_outlined, Icons.monitor_heart, 'Tracker', 2),
                    _buildNavItem(Icons.pets_outlined, Icons.pets, 'My Pets', 3),
                    _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Custom Navigation Item with Animated Active Dot
  Widget _buildNavItem(IconData unselectedIcon, IconData selectedIcon, String label, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => currentIndex = index),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                key: ValueKey(isSelected),
                color: isSelected ? Colors.black87 : Colors.grey.shade400,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.black87 : Colors.grey.shade500,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            // The Premium Detail: Animated Active Indicator Dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
            )
          ],
        ),
      ),
    );
  }
}