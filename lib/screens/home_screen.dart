import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ultra-clean pure white background
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Native bounce effect
          slivers: [
            // 1. Apple-Style Header (FIXED)
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 80.0,
              titleSpacing: 24.0, // FIXED: Replaced titlePadding with titleSpacing
              title: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Good morning, Alex!",
                        style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        "Milo is looking great. 👋",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, // Flat grey background
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Daily Care Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Care",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                          child: const Text("View All", style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _AppleStyleTrackerCard(
                            title: "Breakfast",
                            time: "08:00 AM",
                            icon: Icons.food_bank_outlined,
                            isCompleted: true,
                            activeColor: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _AppleStyleTrackerCard(
                            title: "Evening Walk",
                            time: "05:30 PM",
                            icon: Icons.directions_walk,
                            isCompleted: false,
                            activeColor: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Explore Services Grid
                    const Text(
                      "Explore Services",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _AppleStyleCategoryButton(title: "Grooming", icon: Icons.content_cut, color: Colors.blue),
                        _AppleStyleCategoryButton(title: "Pet Hotel", icon: Icons.hotel, color: Colors.purple),
                        _AppleStyleCategoryButton(title: "Vet Clinic", icon: Icons.local_hospital, color: Colors.teal),
                        _AppleStyleCategoryButton(title: "Pet Store", icon: Icons.shopping_bag, color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Flat Promo Banner
                    _buildFlatPromoBanner(context),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Flat Pastel Trust Banner
  Widget _buildFlatPromoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF26A69A).withOpacity(0.08), // Flat pastel teal
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF26A69A).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.verified_user, color: Color(0xFF26A69A), size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Certified Partners",
                  style: TextStyle(color: Color(0xFF1E8278), fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
                ),
                SizedBox(height: 4),
                Text(
                  "Book with confidence. All shops are 100% verified.",
                  style: TextStyle(color: Colors.teal, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Minimalist Flat Tracker Card
class _AppleStyleTrackerCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final bool isCompleted;
  final MaterialColor activeColor;

  const _AppleStyleTrackerCard({
    required this.title,
    required this.time,
    required this.icon,
    required this.isCompleted,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade50 : activeColor.withOpacity(0.06), // Flat backgrounds
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade200 : activeColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.white : Colors.white, // Crisp white icon background
                  shape: BoxShape.circle,
                  border: Border.all(color: isCompleted ? Colors.grey.shade200 : Colors.transparent),
                ),
                child: Icon(icon, color: isCompleted ? Colors.grey.shade400 : activeColor.shade600, size: 22),
              ),
              if (isCompleted) Icon(Icons.check_circle, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isCompleted ? Colors.grey.shade500 : Colors.black87,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: isCompleted ? Colors.grey.shade400 : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Minimalist Flat Category Button (Replaces the heavy cards)
class _AppleStyleCategoryButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final MaterialColor color;

  const _AppleStyleCategoryButton({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50, // Flat clean grey
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 26, color: color.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}