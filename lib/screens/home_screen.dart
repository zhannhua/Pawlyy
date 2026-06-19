import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Exact Brand Colors from your Pawly logo
  static const Color brandTeal = Color(0xFF2E8C9A);
  static const Color brandOrange = Color(0xFFF5A524);
  // Extracted soft mint background from your new design
  static const Color softBackground = Color(0xFFEEF7F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBackground, // Soft mint background
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Top Navigation Bar (Location & Bell)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.grey.shade400, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Petaling Jaya, Selangor",
                            style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 16),
                        ],
                      ),
                    ),
                    // Notification Bell
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.black87, size: 22),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: brandTeal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Title
                    const Text(
                      "Welcome, Alex",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1.0, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Welcome Banner Block
                    Row(
                      children: [
                        // Square User Profile
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.network(
                                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=200&auto=format&fit=crop', // Placeholder guy
                                width: 65,
                                height: 65,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Pet Greeting Pill
                        Expanded(
                          child: Container(
                            height: 65,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1552053831-71594a27632d?q=80&w=200&auto=format&fit=crop', // Golden retriever puppy
                                    width: 80,
                                    height: 65,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Good morning, Alex!", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      const Text("Milo is looking\nfantastic today! 👋", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.1, color: Colors.black87)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Today's Care Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today's Care",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(foregroundColor: brandTeal),
                          child: const Text("View All", style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rich Media Tracker Cards
                    Row(
                      children: [
                        Expanded(
                          child: _RichTrackerCard(
                            title: "Breakfast",
                            time: "08:00 AM",
                            imageUrl: 'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?q=80&w=300&auto=format&fit=crop', // Bowl placeholder
                            subtitle: "Nourishing Breakfast",
                            statusText: "Completed",
                            statusTime: "8:05 AM",
                            isCompleted: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RichTrackerCard(
                            title: "Evening Walk",
                            time: "05:30 PM",
                            imageUrl: 'https://images.unsplash.com/photo-1517164850305-99a3e65bb47e?q=80&w=300&auto=format&fit=crop', // Park walk placeholder
                            subtitle: "Scenic Walk",
                            statusText: "45 mins planned",
                            statusTime: "Active Tracker",
                            isCompleted: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Explore Services
                    const Text(
                      "Explore Services",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start, // Align to top to handle text wrapping
                      children: const [
                        Expanded(child: _AppleStyleCategoryButton(title: "Grooming\nExpert Grooming", icon: Icons.content_cut, color: Colors.blueGrey)),
                        Expanded(child: _AppleStyleCategoryButton(title: "Pet Hotel\nLuxury Pet Hotel", icon: Icons.hotel, color: Colors.brown)),
                        Expanded(child: _AppleStyleCategoryButton(title: "Vet Clinic\nTop Vet Care", icon: Icons.local_hospital, color: Color(0xFF2E8C9A))),
                        Expanded(child: _AppleStyleCategoryButton(title: "Pet Store\nEssentials Shop", icon: Icons.shopping_cart, color: Color(0xFFF5A524))),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Verified Partner Banner
                    _buildVerifiedBanner(),
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

  // Exact Match Verified Network Banner
  Widget _buildVerifiedBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), // Frosted glass look
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: brandTeal, shape: BoxShape.circle),
                child: const Icon(Icons.shield, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Verified Partner Network", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87, letterSpacing: -0.3)),
                    SizedBox(height: 8),
                    // Simulated mini logos (replace with real Image assets later)
                    Row(
                      children: [
                        _MiniLogo(icon: Icons.local_hospital, color: Colors.blue),
                        SizedBox(width: 8),
                        _MiniLogo(icon: Icons.hotel, color: Colors.orange),
                        SizedBox(width: 8),
                        _MiniLogo(icon: Icons.pets, color: Colors.brown),
                        SizedBox(width: 8),
                        _MiniLogo(icon: Icons.content_cut, color: Colors.teal),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Verified for safety & quality. Book with confidence.",
            style: TextStyle(color: Colors.black87.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// HELPER WIDGETS
// ----------------------------------------------------

// Rich Media Tracker Card (Matches the specific image layout)
class _RichTrackerCard extends StatelessWidget {
  final String title;
  final String time;
  final String imageUrl;
  final String subtitle;
  final String statusText;
  final String statusTime;
  final bool isCompleted;

  const _RichTrackerCard({
    required this.title,
    required this.time,
    required this.imageUrl,
    required this.subtitle,
    required this.statusText,
    required this.statusTime,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240, // Fixed height to match the design
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Time, Icon
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(time, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: HomeScreen.brandTeal, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
              ],
            ),
          ),

          // Image Area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Bottom Row: Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black87, letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                        statusText,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCompleted ? HomeScreen.brandTeal : Colors.grey.shade500
                        )
                    ),
                    if (isCompleted)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(statusTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
                            const SizedBox(width: 4),
                            const Icon(Icons.check, color: HomeScreen.brandTeal, size: 12),
                          ],
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Exact match for the Double-Ring Service Icons
class _AppleStyleCategoryButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _AppleStyleCategoryButton({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Split title and subtitle by newline
    final parts = title.split('\n');
    final mainTitle = parts[0];
    final subTitle = parts.length > 1 ? parts[1] : '';

    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start, // Changed to start so text aligns perfectly
        children: [
          // The specific Double-Ring border style
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.brown.shade100, width: 1.5), // Outer ring
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08), // Soft inner tint
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            mainTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87, letterSpacing: -0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subTitle,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11, color: Colors.grey.shade600, height: 1.2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Helper for the mini logos inside the Verified Banner
class _MiniLogo extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MiniLogo({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}