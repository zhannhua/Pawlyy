import 'package:flutter/material.dart';
import 'service_detail_screen.dart';
import 'location_screen.dart'; // <-- IMPORT ADDED HERE

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ultra-clean pure white background
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Native bounce effect
          slivers: [
            // 1. Modern Immersive Header
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 120.0,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  "Services",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    fontSize: 28,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.map_outlined, color: Colors.black87),
                    // 👇 NAVIGATION ADDED HERE 👇
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LocationScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // 2. Search & Filter Bar
            SliverToBoxAdapter(
              child: _buildSearchBar(context),
            ),

            // 3. Apple-Style Minimalist List
            SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),
                const _AppleStyleServiceCard(
                  name: "Happy Paw Grooming",
                  type: "Premium Grooming",
                  basePrice: "RM 50",
                  rating: "4.8",
                  reviewCount: 124,
                  isVerified: true,
                  distance: "2.5 km",
                ),
                Divider(height: 1, color: Colors.grey.shade200, indent: 110), // Indented divider!
                const _AppleStyleServiceCard(
                  name: "Fluffy Bubbles Pet Salon",
                  type: "Basic Bath & Trim",
                  basePrice: "RM 35",
                  rating: "4.9",
                  reviewCount: 89,
                  isVerified: true,
                  distance: "3.1 km",
                ),
                Divider(height: 1, color: Colors.grey.shade200, indent: 110),
                const _AppleStyleServiceCard(
                  name: "Urban Tails Barkery",
                  type: "Full Grooming",
                  basePrice: "RM 80",
                  rating: "4.5",
                  reviewCount: 42,
                  isVerified: false,
                  distance: "5.0 km",
                ),
                const SizedBox(height: 40), // Bottom padding
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // Modern Flat Search Bar
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100, // Flat grey, no shadow
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Klang Valley...",
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {},
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}

// 3. Ultra-Clean Minimalist Service Card
class _AppleStyleServiceCard extends StatefulWidget {
  final String name;
  final String type;
  final String basePrice;
  final String rating;
  final int reviewCount;
  final bool isVerified;
  final String distance;

  const _AppleStyleServiceCard({
    required this.name,
    required this.type,
    required this.basePrice,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.distance,
  });

  @override
  State<_AppleStyleServiceCard> createState() => _AppleStyleServiceCardState();
}

class _AppleStyleServiceCardState extends State<_AppleStyleServiceCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailScreen(
              shopName: widget.name,
              isVerified: widget.isVerified,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crisp Rounded Image Icon
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
              ),
              child: Icon(Icons.storefront, color: Theme.of(context).colorScheme.primary, size: 32),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row with Heart
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (widget.isVerified)
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                          ],
                        ),
                      ),

                      // Animated Heart
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSaved = !_isSaved;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isSaved ? "Saved to favorites! ❤️" : "Removed from favorites.",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            _isSaved ? Icons.favorite : Icons.favorite_border,
                            color: _isSaved ? Colors.red : Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Subtitle
                  Text(
                    widget.type,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 6),

                  // Minimalist Stats
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${widget.rating} (${widget.reviewCount})",
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text("•", style: TextStyle(color: Colors.grey[400])),
                      ),
                      Text(
                        widget.distance,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Price & Pill Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.basePrice,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),

                      // Apple-Style Pill Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Book",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}