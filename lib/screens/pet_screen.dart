import 'package:flutter/material.dart';
import 'add_pet_screen.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';

class PetScreen extends StatelessWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Grabs the list of pets from the Provider
    final pets = context.watch<PetProvider>().pets;

    return Scaffold(
      backgroundColor: Colors.white, // Ultra-clean pure white background

      // 1. Sleek Apple-Style Bottom Action Bar (Replaces the Floating Action Button)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPetScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87, // Sleek black button
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20),
                SizedBox(width: 8),
                Text("Add New Pet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(), // Native bounce effect
        slivers: [
          // 2. Apple-Style Dynamic Header
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            expandedHeight: 100.0,
            flexibleSpace: const FlexibleSpaceBar(
              titlePadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                "My Pets",
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
                    child: const Icon(Icons.history, color: Colors.black87, size: 20),
                  ),
                  tooltip: "Medical History",
                  onPressed: () {},
                ),
              ),
            ],
          ),

          // 3. Pet List or Empty State
          if (pets.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final pet = pets[index];
                    return _AppleStylePetCard(
                      name: pet.name,
                      species: pet.species,
                      breed: pet.breed,
                      weight: pet.weight,
                      gender: pet.gender,
                      age: "Born: ${pet.birthday.year}",
                      color: pet.species == 'Dog' ? Colors.orange : Colors.teal,
                    );
                  },
                  childCount: pets.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Beautiful Minimalist Empty State
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 64,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No pets added yet!",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap the button below to register your furry friend.",
            style: TextStyle(color: Colors.grey[500], fontSize: 15),
          ),
          const SizedBox(height: 60), // Offset for visual center
        ],
      ),
    );
  }
}

// 4. Flat Pastel Pet Card
class _AppleStylePetCard extends StatelessWidget {
  final String name;
  final String species;
  final String breed;
  final double weight;
  final String gender;
  final String age;
  final MaterialColor color;

  const _AppleStylePetCard({
    required this.name,
    required this.species,
    required this.breed,
    required this.weight,
    required this.gender,
    required this.age,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06), // Flat pastel background, NO SHADOW
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)), // Subtle matching border
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Future: Open detailed pet profile/edit screen
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header: Avatar, Name, and Breed
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white, // Crisp white pop against pastel card
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        species == "Dog" ? Icons.pets : Icons.cruelty_free,
                        size: 30,
                        color: color.shade600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: Colors.black87,
                                ),
                              ),
                              Icon(
                                gender == "Male" ? Icons.male : Icons.female,
                                color: gender == "Male" ? Colors.blue : Colors.pink,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            breed,
                            style: TextStyle(
                              fontSize: 14,
                              color: color.shade700, // Matches text to the card's theme
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(height: 1, color: color.withOpacity(0.1)),
                const SizedBox(height: 20),

                // Footer: Flat White Stat Pills
                Row(
                  children: [
                    Expanded(child: _FlatStatPill(label: "Age", value: age)),
                    const SizedBox(width: 12),
                    Expanded(child: _FlatStatPill(label: "Weight", value: "${weight.toStringAsFixed(1)} kg")),
                    const SizedBox(width: 12),
                    Expanded(child: _FlatStatPill(label: "Species", value: species)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 5. Flat White Pill Widget (Pops beautifully against the pastel card)
class _FlatStatPill extends StatelessWidget {
  final String label;
  final String value;

  const _FlatStatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6), // Soft translucent white
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}