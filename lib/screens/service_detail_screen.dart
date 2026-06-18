import 'package:flutter/material.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String shopName;
  final bool isVerified;

  const ServiceDetailScreen({
    super.key,
    this.shopName = "Happy Paw Grooming",
    this.isVerified = true,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  // Track which services the user has selected
  final Set<String> _selectedServices = {};
  double _totalPrice = 0.0;

  void _toggleService(String serviceName, double price) {
    setState(() {
      if (_selectedServices.contains(serviceName)) {
        _selectedServices.remove(serviceName);
        _totalPrice -= price;
      } else {
        _selectedServices.add(serviceName);
        _totalPrice += price;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 1. Attractive Header with Shop Image
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.blue[100],
                child: const Center(
                  child: Icon(Icons.store, size: 80, color: Colors.blue),
                ),
              ),
            ),
          ),

          // 2. Shop Info & Trust Badges
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.shopName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.isVerified)
                        const Icon(Icons.verified, color: Colors.blue, size: 24),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 4),
                      Text("4.8", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(" (124 verified reviews)", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey, size: 20),
                      SizedBox(width: 4),
                      Text("Klang Valley • 2.5 km away", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(),
                  ),
                  const Text(
                    "Transparent Pricing & Services",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 3. Service Catalog (Combos & Basics)
          SliverList(
            delegate: SliverChildListDelegate([
              _buildServiceItem(
                name: "Basic Bath & Fluff",
                description: "Includes bath, blow dry, ear cleaning, and nail clipping.",
                price: 50.0,
                duration: "1.5 hrs",
              ),
              _buildServiceItem(
                name: "Full Premium Grooming",
                description: "Basic bath + full body styling and sanitary trim.",
                price: 85.0,
                duration: "2.5 hrs",
              ),
              // Combo Promotion Strategy
              _buildServiceItem(
                name: "Spa Combo (Best Value!)",
                description: "Full Grooming + Blueberry Facial + Paw Balm treatment.",
                price: 110.0,
                duration: "3 hrs",
                isPromo: true,
              ),
              const SizedBox(height: 100), // Padding for bottom bar
            ]),
          ),
        ],
      ),

      // 4. Sticky Bottom Bar for Booking
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_selectedServices.length} selected",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  Text(
                    "RM ${_totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _selectedServices.isEmpty ? null : () {
                  // Future: Navigate to Date/Time Selection Calendar
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Select Time"),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper widget to build individual service cards
  Widget _buildServiceItem({
    required String name,
    required String description,
    required double price,
    required String duration,
    bool isPromo = false,
  }) {
    final isSelected = _selectedServices.contains(name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () => _toggleService(name, price),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPromo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        // FIXED: Changed from EdgeInsets.bottom(8) to EdgeInsets.only(bottom: 8)
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Special Promo",
                          style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "RM ${price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                    size: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}