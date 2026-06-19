import 'package:flutter/material.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Select Location",
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Flat Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search city or neighborhood...",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Current Location Button
              InkWell(
                onTap: () {
                  // Future: Trigger GPS location fetch
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Use Current Location",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 32),

              const Text(
                  "Recent Locations",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)
              ),
              const SizedBox(height: 16),

              // 3. Apple-Style Location List
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildLocationTile(context, "Petaling Jaya, Selangor", "Malaysia", true),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 40),
                    _buildLocationTile(context, "Subang Jaya, Selangor", "Malaysia", false),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 40),
                    _buildLocationTile(context, "Kuala Lumpur", "Federal Territory", false),
                    Divider(height: 1, color: Colors.grey.shade100, indent: 40),
                    _buildLocationTile(context, "Shah Alam, Selangor", "Malaysia", false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for clean location rows
  Widget _buildLocationTile(BuildContext context, String title, String subtitle, bool isSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.location_on_outlined,
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
        size: 26,
      ),
      title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: Colors.black87,
            fontSize: 16,
            letterSpacing: -0.3,
          )
      ),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: () {
        // Future: Update global state with new location
        Navigator.pop(context);
      },
    );
  }
}