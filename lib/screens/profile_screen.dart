import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ultra-clean pure white background
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(), // Modern native bounce effect
          slivers: [
            // 1. Apple-Style Dynamic Header
            SliverAppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              pinned: true,
              expandedHeight: 100.0,
              flexibleSpace: const FlexibleSpaceBar(
                titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                title: Text(
                  "Profile",
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
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, // Flat grey background, no shadow
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_outlined, color: Colors.black87, size: 20),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),

            // 2. Main Profile Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildUserInfo(context),
                  const SizedBox(height: 32),

                  _buildRewardsSection(context),
                  const SizedBox(height: 32),

                  _buildPetsSection(context),
                  const SizedBox(height: 32),

                  _buildSettingsSection(context),
                  const SizedBox(height: 60), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. User Info Card (Clean & Flat)
  Widget _buildUserInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            backgroundColor: Colors.grey,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Alex Johnson",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  "+60 12-345 6789",
                  style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20), // Pill shape
                  ),
                  child: Text(
                    "New User (28 days left)",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Rewards & Referrals
  Widget _buildRewardsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rewards & Promos",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AppleStyleRewardCard(
                  title: "My Vouchers",
                  subtitle: "2 Available",
                  icon: Icons.confirmation_num_outlined,
                  color: Colors.orange,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AppleStyleRewardCard(
                  title: "Invite Friends",
                  subtitle: "Earn RM 5",
                  icon: Icons.card_giftcard,
                  color: Colors.teal,
                  onTap: () => _showReferralBottomSheet(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Pet Hub
  Widget _buildPetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "My Pets",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                child: const Text("Manage", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              _AppleStylePetAvatar(name: "Milo", type: "Dog"),
              _AppleStylePetAvatar(name: "Luna", type: "Cat"),
              _AppleStyleAddPetButton(),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Apple-Style Settings Menu
  Widget _buildSettingsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "General",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200), // Flat subtle outline, no shadow
            ),
            child: Column(
              children: [
                _AppleStyleMenuTile(icon: Icons.history, title: "Booking History", isFirst: true),
                Divider(height: 1, color: Colors.grey.shade200, indent: 56), // Indented divider
                _AppleStyleMenuTile(icon: Icons.favorite_border, title: "Saved Shops"),
                Divider(height: 1, color: Colors.grey.shade200, indent: 56), // Indented divider
                _AppleStyleMenuTile(icon: Icons.help_outline, title: "Help & Support", isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Flat & Clean Bottom Sheet
  void _showReferralBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.group_add, size: 40, color: Colors.teal),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Invite Friends, Earn RM5!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  "Share your code. When a friend signs up and completes their first paid booking, you both get an RM5 voucher.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100, // Flat grey, no border
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ALEX-PAW-24",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.teal),
                      ),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: "ALEX-PAW-24"));
                          Navigator.pop(context); // Close sheet on copy
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Referral code copied!", style: TextStyle(fontWeight: FontWeight.bold)),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.teal.shade600,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.copy, color: Colors.teal, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.black87, // Sleek black button
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Share Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Apple-Style Helper Widgets ---

class _AppleStyleRewardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _AppleStyleRewardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06), // Flat pastel background, NO SHADOW
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: color.shade600, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: color.shade700, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _AppleStylePetAvatar extends StatelessWidget {
  final String name;
  final String type;

  const _AppleStylePetAvatar({required this.name, required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            child: Icon(
              type == "Dog" ? Icons.pets : Icons.cruelty_free,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _AppleStyleAddPetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(36),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1.5, style: BorderStyle.solid),
            ),
            child: const Icon(Icons.add, size: 28, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 10),
        const Text("Add Pet", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}

class _AppleStyleMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isFirst;
  final bool isLast;

  const _AppleStyleMenuTile({
    required this.icon,
    required this.title,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), // Flat icon background
              child: Icon(icon, color: Colors.grey[700], size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}