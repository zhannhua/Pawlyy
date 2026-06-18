import 'package:flutter/material.dart';
import '../widgets/service_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Softer background
      appBar: AppBar(
        title: const Text(
          "🐾 Pawly",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Personalized Greeting
            const Text(
              "Hello, Alex! 👋",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Milo is looking great today.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Retention Engine: Daily Care Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Daily Care",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text("View All"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDailyTrackerRow(),
            const SizedBox(height: 32),

            // 3. Monetization Engine: Services
            const Text(
              "Book Services",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ServiceCard(
                  title: "Grooming",
                  icon: Icons.content_cut,
                  onTap: () {},
                ),
                ServiceCard(
                  title: "Pet Hotel",
                  icon: Icons.hotel,
                  onTap: () {},
                ),
                ServiceCard(
                  title: "Vet Clinic",
                  icon: Icons.local_hospital,
                  onTap: () {},
                ),
                ServiceCard(
                  title: "Pet Store",
                  icon: Icons.shopping_bag,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 4. Social Proof / Trust Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified, color: Colors.blue, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pawly Certified Shops",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Book with confidence. All our partners are verified.",
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for the daily tracker
  Widget _buildDailyTrackerRow() {
    return Row(
      children: [
        Expanded(
          child: _TrackerCard(
            title: "Breakfast",
            time: "08:00 AM",
            icon: Icons.food_bank,
            isCompleted: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TrackerCard(
            title: "Walk",
            time: "05:30 PM",
            icon: Icons.directions_walk,
            isCompleted: false,
          ),
        ),
      ],
    );
  }
}

// A new private widget just for the Home Screen trackers
class _TrackerCard extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final bool isCompleted;

  const _TrackerCard({
    required this.title,
    required this.time,
    required this.icon,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isCompleted ? Colors.green : Colors.grey[700],
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}