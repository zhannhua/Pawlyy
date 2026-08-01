import 'package:flutter/material.dart';
// Import your existing Pet model!
import '../models/pet_model.dart';

class PetProvider extends ChangeNotifier {
  // Pre-loaded dummy data using your exact Pet model structure
  final List<Pet> _pets = [
    Pet(
      id: '1',
      name: 'Milo',
      species: 'Dog',
      breed: 'Golden Retriever',
      gender: 'Male',
      birthday: DateTime.now().subtract(const Duration(days: 1150)),
      weight: 32.5,
      imageUrl: '', // Added imageUrl to match your model
    ),
    Pet(
      id: '2',
      name: 'Luna',
      species: 'Cat',
      breed: 'British Shorthair',
      gender: 'Female',
      birthday: DateTime.now().subtract(const Duration(days: 500)),
      weight: 4.2,
      imageUrl: '', // Added imageUrl to match your model
    ),
  ];

  List<Pet> get pets => _pets;

  // The function to add a new pet
  void addPet(Pet pet) {
    _pets.add(pet);
    notifyListeners();
  }
}
