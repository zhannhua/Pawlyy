import 'package:flutter/material.dart';
import 'add_pet_screen.dart';
import 'package:provider/provider.dart';
import '../providers/pet_provider.dart';

class PetScreen extends StatelessWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Pets",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Medical History",
            onPressed: () {},
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          PetIdentityCard(
            name: "Milo",
            species: "Dog",
            breed: "Golden Retriever",
            weight: 32.5,
            gender: "Male",
            age: "3 yrs 2 mos",
            color: Colors.orange,
          ),
          PetIdentityCard(
            name: "Luna",
            species: "Cat",
            breed: "British Shorthair",
            weight: 4.2,
            gender: "Female",
            age: "1 yr 5 mos",
            color: Colors.teal,
          ),
        ],
      ),
      // Floating Action Button to register a new pet
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPetScreen(), // <-- This is where it gets used!
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Pet"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class PetIdentityCard extends StatelessWidget {
  final String name;
  final String species;
  final String breed;
  final double weight;
  final String gender;
  final String age;
  final MaterialColor color;

  const PetIdentityCard({
    super.key,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // Future: Open detailed pet profile/edit screen
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header: Avatar, Name, and Breed
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: color.shade200, width: 2),
                    ),
                    child: Icon(
                      species == "Dog" ? Icons.pets : Icons.cruelty_free,
                      size: 35,
                      color: color.shade700,
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              gender == "Male" ? Icons.male : Icons.female,
                              color: gender == "Male" ? Colors.blue : Colors.pink,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          breed,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),
              // Footer: Quick Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _PetStatDetail(label: "Age", value: age),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _PetStatDetail(label: "Weight", value: "${weight.toStringAsFixed(1)} kg"),
                  Container(height: 30, width: 1, color: Colors.grey[300]),
                  _PetStatDetail(label: "Species", value: species),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for the quick stats at the bottom of the card
class _PetStatDetail extends StatelessWidget {
  final String label;
  final String value;

  const _PetStatDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}