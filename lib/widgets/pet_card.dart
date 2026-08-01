import 'package:flutter/material.dart';

class PetCard extends StatelessWidget {
  final String name;
  final String species;
  final String breed;
  final double weight;
  final String gender;

  const PetCard({
    super.key,
    required this.name,
    required this.species,
    required this.breed,
    required this.weight,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, child: Icon(Icons.pets, size: 30)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$species • $breed'),
                  const SizedBox(height: 4),
                  Text('Weight: ${weight.toStringAsFixed(1)} kg'),
                  Text('Gender: $gender'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
