// Model representing a user in the driver app.
// Includes personal, contact, bank, and role information.
// Provides factory constructor to build from Firestore data.

import 'package:firebase_auth/firebase_auth.dart';

/// Represents a user profile with personal details and metadata.
/// Contains fields for bank info, role, language, experience, and last tour date.
/// Factory constructor converts Firestore map into [UserModel] instance.
class UserModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String fin;
  final String role;
  final String birthday;
  final String languageSpoken;
  final String? address;
  final String? personalPhoto;
  final String? vehicleType;
  final String experience;
  final String gender;
  final DateTime lastTourEndDate;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.fin,
    required this.role,
    required this.languageSpoken,
    required this.birthday,
    required this.experience,
    required this.gender,
    required this.lastTourEndDate,
    this.address,
    this.personalPhoto,
    this.vehicleType,
  });

  /// Creates a [UserModel] from a map typically fetched from Firestore.
  /// Uses the currently authenticated Firebase user UID as [userId].
  /// Provides default values if any fields are missing or user is not authenticated.
  factory UserModel.fromMap(Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return UserModel(
        userId: user.uid,
        firstName: data['First Name'] ?? '',
        lastName: data['Last Name'] ?? '',
        email: data['E-mail'] ?? '',
        phoneNumber: data['Phone number'] ?? '',
        birthday: data['Day of Birth'],
        experience: data['Experience'],
        gender: data['Gender'],
        fin: data['Bank Details']['FIN'] ?? '',
        role: data['Role'] ?? '',
        address: data['Bank Details']['Address'],
        personalPhoto: data['personalPhoto'],
        vehicleType: data['Vehicle Type'],
        languageSpoken: data['Language spoken'],
        lastTourEndDate: data['Tour end Date'].toDate(),
      );
    }
    return UserModel(
      userId: "",
      firstName: '',
      lastName: '',
      email: '',
      phoneNumber: '',
      birthday: "",
      experience: "",
      gender: "",
      fin: '',
      role: '',
      address: "",
      personalPhoto: "",
      vehicleType: "",
      languageSpoken: "",
      lastTourEndDate: DateTime.now(),
    );
  }
}
