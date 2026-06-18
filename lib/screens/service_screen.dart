import 'package:flutter/material.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Grooming Services",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search in Klang Valley...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // Future: Open filter bottom sheet (Distance, Price, Rating)
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // 2. Service List with Trust System
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ServiceItem(
                  name: "Happy Paw Grooming",
                  type: "Premium Grooming",
                  basePrice: "RM 50",
                  rating: "4.8",
                  reviewCount: 124,
                  isVerified: true,
                  distance: "2.5 km",
                ),
                ServiceItem(
                  name: "Fluffy Bubbles Pet Salon",
                  type: "Basic Bath & Trim",
                  basePrice: "RM 35",
                  rating: "4.9",
                  reviewCount: 89,
                  isVerified: true,
                  distance: "3.1 km",
                ),
                ServiceItem(
                  name: "Urban Tails Barkery",
                  type: "Full Grooming",
                  basePrice: "RM 80",
                  rating: "4.5",
                  reviewCount: 42,
                  isVerified: false,
                  distance: "5.0 km",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final String name;
  final String type;
  final String basePrice;
  final String rating;
  final int reviewCount;
  final bool isVerified;
  final String distance;

  const ServiceItem({
    super.key,
    required this.name,
    required this.type,
    required this.basePrice,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Image Placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, color: Colors.blue, size: 40),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Trust Element: Verified Badge
                          if (isVerified)
                            const Icon(Icons.verified, color: Colors.blue, size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$type • $distance",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 8),

                      // Trust Element: Ratings Breakdown
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            " ($reviewCount reviews)",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Call to Action & Transparent Pricing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Starting from",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      basePrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Future: Open individual shop menu/catalog
                  },
                  child: const Text("View Prices & Book"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}