// Handles assigning a user as a driver or guide to a specific tour or car.
// Updates Firestore collections for Cars/Guides, Users, and Chat.
// Sends assignment data to an external API endpoint.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/user_assign.dart/user_assign_post_api.dart';
import 'package:onemoretour/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Assigns the current user to a tour or car by updating Firestore and notifying external API.
///
/// Parameters:
/// - [docId]: The Firestore document ID of the tour or car.
/// - [baseUrl]: The base URL for the external API endpoint.
/// - [collection]: Firestore collection name, either 'Cars' or 'Guides'.
/// - [carName]: Name of the car or tour.
/// - [vehicleRegistrationNumber]: Registration number of the vehicle (used if collection is 'Cars').
/// - [tourEdnDAte]: Timestamp indicating the tour's end date.
///
/// If the user is not authenticated, the function returns early.
/// Upon successful Firestore updates, it triggers an API call and then pops the current navigation context.
Future<void> userAssign({
  required String docId,
  required String baseUrl,
  required String collection,
  required String carName,
  required String vehicleRegistrationNumber,
  required Timestamp tourEdnDAte,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final userId = user.uid;
  final userEmail = user.email;
  final UserAssignPostApi userAssignPostApi = UserAssignPostApi();

  if (userEmail != null) {
    final fieldToUpdate = collection == 'Cars' ? 'Driver' : 'Guide';

    await FirebaseFirestore.instance.collection(collection).doc(docId).set({
      fieldToUpdate: userId,
      if (collection == 'Cars')
        'VehicleRegistrationNumber': vehicleRegistrationNumber,
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance.collection('Users').doc(userId).set({
      "Tour end Date": tourEdnDAte,
    }, SetOptions(merge: true));

    final chatDocRef = FirebaseFirestore.instance
        .collection('Chat')
        .doc(userId);

    await chatDocRef.set({
      'createdAt': FieldValue.serverTimestamp(),
      'userEmail': userEmail,
    }, SetOptions(merge: true));

    final chatSubCollectionRef = chatDocRef.collection(docId);

    await chatSubCollectionRef.doc('init').set({
      'createdAt': FieldValue.serverTimestamp(),
      'initializedBy': userEmail,
    });

    userAssignPostApi.postData({
      'email': userEmail,
      'ID': docId,
      'CarName': carName,
    }, baseUrl);
  }

  navigatorKey.currentState?.pop();
}
