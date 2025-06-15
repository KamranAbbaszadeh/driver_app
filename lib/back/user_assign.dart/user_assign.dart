import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/user_assign.dart/user_assign_post_api.dart';
import 'package:onemoretour/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> userAssign({
  required String docId,
  required String baseUrl,
  required String collection,
  required String carName,
  required String vehicleRegistrationNumber,
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
