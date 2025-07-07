// Handles user sign-up and update logic for Firebase Auth and Firestore.
// Also sends user data to an external API and saves FCM tokens.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:onemoretour/back/auth/post_api.dart';
import 'package:onemoretour/front/auth/waiting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Registers a new user with Firebase Auth and Firestore or updates existing user data.
/// Also posts user information to an external API and saves their FCM token.
Future<void> signUp({
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required TextEditingController firstNameController,
  required TextEditingController lastNameController,
  required TextEditingController fathersNameController,
  required TextEditingController phoneNumberController,
  required TextEditingController languageController,
  required TextEditingController birthDayController,
  required TextEditingController experienceController,
  required TextEditingController vehicleTypeController,
  required TextEditingController roleController,
  required TextEditingController genderController,
  required dynamic context,
}) async {
  // Check if user is already signed in. If not, proceed with registration.
  final user = FirebaseAuth.instance.currentUser;
  try {
    if (user == null) {
      final ApiService apiService = ApiService();

      // Step 1: Create Firebase Auth account using email and password.
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim().toLowerCase(),
            password: passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      // Step 2: Store initial user profile in Firestore under 'Users' collection.
      await addUserDetails(
        birthDayController: birthDayController,
        emailController: emailController,
        experienceController: experienceController,
        fathersNameController: fathersNameController,
        firstNameController: firstNameController,
        genderController: genderController,
        languageController: languageController,
        lastNameController: lastNameController,
        phoneNumberController: phoneNumberController,
        roleController: roleController,
        userCredential: userCredential,
        vehicleTypeController: vehicleTypeController,
      );

      // Step 3: Validate Firestore record and ensure 'Role' field exists.
      final userDocSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();

      if (!userDocSnapshot.exists ||
          !(userDocSnapshot.data()?.containsKey('Role') ?? false)) {
        throw Exception(
          "User Firestore document missing or 'Role' field missing.",
        );
      }

      // Step 4: Save FCM token to Firestore.
      await FirebaseApi.instance.saveFCMToken(user.uid);

      DateTime parsedDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(birthDayController.text);
      String jsonFormattedDate = parsedDate.toIso8601String();
      double yOE = double.parse(experienceController.text);

      Map<String, dynamic> data = {
        'FirstName': firstNameController.text,
        'LastName': lastNameController.text,
        'FatherName': fathersNameController.text,
        'mobile': phoneNumberController.text,
        'email': emailController.text.toLowerCase(),
        'YoE': yOE,
        'Role': roleController.text,
        'Languages': languageController.text,
        'VehicleCategory': vehicleTypeController.text,
        'Gender': genderController.text,
        'DateofBirth': jsonFormattedDate,
        'Password': passwordController.text,
        'UID': user.uid,
      };

      // Step 5: Post user data to external API.
      final success = await apiService.postData(data);

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Data posted successfully!")));
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => WaitingPage()),
        (route) => false,
      );
    } else {
      final ApiServiceUpdate apiService = ApiServiceUpdate();
      await updateUserDetails(
        birthDayController: birthDayController,
        emailController: emailController,
        experienceController: experienceController,
        fathersNameController: fathersNameController,
        firstNameController: firstNameController,
        genderController: genderController,
        languageController: languageController,
        lastNameController: lastNameController,
        phoneNumberController: phoneNumberController,
        roleController: roleController,
        userID: user.uid,
        vehicleTypeController: vehicleTypeController,
      );

      DateTime parsedDate = DateFormat(
        'dd/MM/yyyy',
      ).parse(birthDayController.text);
      String jsonFormattedDate = parsedDate.toIso8601String();
      double yOE = double.parse(experienceController.text);

      Map<String, dynamic> data = {
        'FirstName': firstNameController.text,
        'LastName': lastNameController.text,
        'FatherName': fathersNameController.text,
        'mobile': phoneNumberController.text,
        'email': emailController.text.toLowerCase(),
        'YoE': yOE,
        'Role': roleController.text,
        'Languages': languageController.text,
        'VehicleCategory': vehicleTypeController.text,
        'Gender': genderController.text,
        'DateofBirth': jsonFormattedDate,
        'Password': passwordController.text,
        'UID': user.uid,
      };

      final success = await apiService.postData(data);

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Data posted successfully!")));
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => WaitingPage()),
        (route) => false,
      );
    }
  } catch (e) {
    rethrow;
  }
}

/// Adds initial user data to Firestore under 'Users' collection.
/// Structure varies depending on user role (Guide vs Driver).
Future<void> addUserDetails({
  required TextEditingController emailController,
  required TextEditingController firstNameController,
  required TextEditingController lastNameController,
  required TextEditingController fathersNameController,
  required TextEditingController phoneNumberController,
  required TextEditingController languageController,
  required TextEditingController birthDayController,
  required TextEditingController experienceController,
  required TextEditingController vehicleTypeController,
  required TextEditingController roleController,
  required TextEditingController genderController,
  required UserCredential userCredential,
}) async {
  try {
    // Add user details to Firestore
    roleController.text == 'Guide'
        ? await FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid)
            .set({
              'E-mail': emailController.text.trim().toLowerCase(),
              'First Name': firstNameController.text.trim(),
              'Last Name': lastNameController.text.trim(),
              'Father\'s Name': fathersNameController.text.trim(),
              'Gender': genderController.text.trim(),
              'Day of Birth': birthDayController.text.trim(),
              'Phone number': phoneNumberController.text.trim(),
              'Language spoken': languageController.text.trim(),
              'Role': roleController.text.trim(),
              'Experience': '${experienceController.text.trim()} years',
              'Application Form Verified': false,
              'Personal & Car Details Form Verified': false,
              'Application Form Decline': false,
              'Personal & Car Details Decline': false,
              'Contract Signing Decline': false,
              'Application Form': 'APPLICATION RECEIVED',
              'Personal & Car Details Form': 'PENDING',
              'Contract Signing': 'PENDING',
              'Registration Completed': false,
            })
        : await FirebaseFirestore.instance
            .collection('Users')
            .doc(userCredential.user!.uid)
            .set({
              'E-mail': emailController.text.trim().toLowerCase(),
              'First Name': firstNameController.text.trim(),
              'Last Name': lastNameController.text.trim(),
              'Father\'s Name': fathersNameController.text.trim(),
              'Gender': genderController.text.trim(),
              'Day of Birth': birthDayController.text.trim(),
              'Phone number': phoneNumberController.text.trim(),
              'Language spoken': languageController.text.trim(),
              'Role': roleController.text.trim(),
              'Experience': '${experienceController.text.trim()} years',
              'Vehicle Type': vehicleTypeController.text.trim(),
              'Application Form Verified': false,
              'Personal & Car Details Form Verified': false,
              'Application Form Decline': false,
              'Personal & Car Details Decline': false,
              'Contract Signing Decline': false,
              'Application Form': 'APPLICATION RECEIVED',
              'Personal & Car Details Form': 'PENDING',
              'Contract Signing': 'PENDING',
              'Registration Completed': false,
            });
  } catch (e) {
    throw Exception('Error adding user details: ${e.toString()}');
  }
}

/// Updates existing Firestore user document with new profile data.
/// Structure varies depending on user role (Guide vs Driver).
Future<void> updateUserDetails({
  required TextEditingController emailController,
  required TextEditingController firstNameController,
  required TextEditingController lastNameController,
  required TextEditingController fathersNameController,
  required TextEditingController phoneNumberController,
  required TextEditingController languageController,
  required TextEditingController birthDayController,
  required TextEditingController experienceController,
  required TextEditingController vehicleTypeController,
  required TextEditingController roleController,
  required TextEditingController genderController,
  required String userID,
}) async {
  try {
    // Add user details to Firestore
    roleController.text == 'Guide'
        ? await FirebaseFirestore.instance
            .collection('Users')
            .doc(userID)
            .update({
              'E-mail': emailController.text.trim().toLowerCase(),
              'First Name': firstNameController.text.trim(),
              'Last Name': lastNameController.text.trim(),
              'Father\'s Name': fathersNameController.text.trim(),
              'Gender': genderController.text.trim(),
              'Day of Birth': birthDayController.text.trim(),
              'Phone number': phoneNumberController.text.trim(),
              'Language spoken': languageController.text.trim(),
              'Role': roleController.text.trim(),
              'Experience': '${experienceController.text.trim()} years',
              'Application Form Verified': false,
              'Personal & Car Details Form Verified': false,
              'Application Form Decline': false,
              'Personal & Car Details Decline': false,
              'Contract Signing Decline': false,
              'Application Form': 'APPLICATION RECEIVED',
              'Personal & Car Details Form': 'PENDING',
              'Contract Signing': 'PENDING',
              'Registration Completed': false,
            })
        : await FirebaseFirestore.instance
            .collection('Users')
            .doc(userID)
            .update({
              'E-mail': emailController.text.trim().toLowerCase(),
              'First Name': firstNameController.text.trim(),
              'Last Name': lastNameController.text.trim(),
              'Father\'s Name': fathersNameController.text.trim(),
              'Gender': genderController.text.trim(),
              'Day of Birth': birthDayController.text.trim(),
              'Phone number': phoneNumberController.text.trim(),
              'Language spoken': languageController.text.trim(),
              'Role': roleController.text.trim(),
              'Experience': '${experienceController.text.trim()} years',
              'Vehicle Type': vehicleTypeController.text.trim(),
              'Application Form Verified': false,
              'Personal & Car Details Form Verified': false,
              'Application Form Decline': false,
              'Personal & Car Details Decline': false,
              'Contract Signing Decline': false,
              'Application Form': 'APPLICATION RECEIVED',
              'Personal & Car Details Form': 'PENDING',
              'Contract Signing': 'PENDING',
              'Registration Completed': false,
            });
  } catch (e) {
    throw Exception('Error adding user details: ${e.toString()}');
  }
}
