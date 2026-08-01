import 'package:flutter/material.dart';
import 'service_detail_screen.dart';
import 'location_screen.dart';

class ServiceScreen extends StatelessWidget {
  const ServiceScreen({super.key});

  // Extracted soft mint background from your new design
  static const Color softBackground = Color(0xFFEEF7F7);
  static const Color brandOrange = Color(0xFFF5A524);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground, // Soft mint background
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Immersive Header
            SliverAppBar(
              backgroundColor: softBackground,
              elevation: 0,
              pinned: true,
              expandedHeight: 80.0,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                title: Text(
                  "Services",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    fontSize: 32,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.map_outlined,
                      color: Colors.black87,
                      size: 28,
                    ),
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
            SliverToBoxAdapter(child: _buildSearchBar(context)),

            // 3. Rich Media Service Cards
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _RichServiceCard(
                    name: "Happy Paw Grooming",
                    type: "Premium Grooming",
                    basePrice: "RM 50",
                    rating: "4.8",
                    reviewCount: 124,
                    isVerified: true,
                    distance: "2.5 km",
                    bottomLeftText: "Nourishing Premium Trim",
                    imageUrl:
                        'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?q=80&w=300&auto=format&fit=crop', // Maltese
                    badgeIcon: Icons.pets,
                    badgeText: "Premium",
                    isPremium: true,
                  ),
                  const _RichServiceCard(
                    name: "Fluffy Bubbles Pet Salon",
                    type: "Basic Bath & Trim",
                    basePrice: "RM 35",
                    rating: "4.9",
                    reviewCount: 89,
                    isVerified: true,
                    distance: "3.1 km",
                    bottomLeftText: "Gentle Dry\n& Brush",
                    imageUrl:
                        'https://images.unsplash.com/photo-1597626133663-cb34ae9231f4?q=80&w=300&auto=format&fit=crop', // Corgi
                    badgeIcon: Icons.cleaning_services,
                    badgeText: "Basic",
                    isPremium: false,
                  ),
                  const _RichServiceCard(
                    name: "Urban Tails Barkery",
                    type: "Full Grooming",
                    basePrice: "RM 80",
                    rating: "4.5",
                    reviewCount: 42,
                    isVerified: false,
                    distance: "5.0 km",
                    bottomLeftText: "Artisan Treats\n& Full Care",
                    imageUrl:
                        'https://images.unsplash.com/photo-1582798358481-d199fb7347bb?q=80&w=300&auto=format&fit=crop', // Treats
                    badgeIcon: Icons.cookie,
                    badgeText: "Full",
                    isPremium: false,
                  ),
                  const SizedBox(
                    height: 80,
                  ), // Bottom padding for scrolling over navbar
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // White Flat Search Bar
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search Klang Valley...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
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

// ----------------------------------------------------
// RICH MEDIA SERVICE CARD
// ----------------------------------------------------
class _RichServiceCard extends StatefulWidget {
  final String name;
  final String type;
  final String basePrice;
  final String rating;
  final int reviewCount;
  final bool isVerified;
  final String distance;
  final String bottomLeftText;
  final String imageUrl;
  final IconData badgeIcon;
  final String badgeText;
  final bool isPremium;

  const _RichServiceCard({
    required this.name,
    required this.type,
    required this.basePrice,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.distance,
    required this.bottomLeftText,
    required this.imageUrl,
    required this.badgeIcon,
    required this.badgeText,
    this.isPremium = false,
  });

  @override
  State<_RichServiceCard> createState() => _RichServiceCardState();
}

class _RichServiceCardState extends State<_RichServiceCard> {
  bool _isSaved = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Rich Image + Badge + Subtext
            SizedBox(
              width: 110,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main Image
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.grey.shade100,
                        backgroundImage: NetworkImage(widget.imageUrl),
                      ),
                      // Floating Badge
                      Positioned(
                        right: -10,
                        top: 0,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.badgeIcon,
                                size: 18,
                                color: widget.isPremium
                                    ? Colors.brown.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isPremium
                                      ? ServiceScreen.brandOrange
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  widget.badgeText,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: widget.isPremium
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.bottomLeftText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      height: 1.2,
                      letterSpacing: -0.3,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Column: Details & Booking
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Heart
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: -0.5,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (widget.isVerified)
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.type,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSaved = !_isSaved;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            _isSaved ? Icons.favorite : Icons.favorite_border,
                            color: _isSaved ? Colors.red : Colors.grey.shade400,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ratings Row
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.rating,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        " (${widget.reviewCount} Reviews)",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini Review Avatars Stack
                      SizedBox(
                        width: 45,
                        height: 20,
                        child: Stack(
                          children: [
                            _buildMiniAvatar(
                              'https://i.pravatar.cc/150?img=32',
                              0,
                            ),
                            _buildMiniAvatar(
                              'https://i.pravatar.cc/150?img=44',
                              12,
                            ),
                            _buildMiniAvatar(
                              'https://i.pravatar.cc/150?img=68',
                              24,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Location Row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey.shade500,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.distance,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Row: Price Glow & Book Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price Glow Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isPremium
                                ? Colors.orange.shade200
                                : Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: widget.isPremium
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          widget.basePrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            letterSpacing: -0.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),

                      // Orange Book Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: ServiceScreen.brandOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Book",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.white,
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

  // Helper for overlapping avatars
  Widget _buildMiniAvatar(String url, double leftOffset) {
    return Positioned(
      left: leftOffset,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: CircleAvatar(radius: 8, backgroundImage: NetworkImage(url)),
      ),
    );
  }
}
