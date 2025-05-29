import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/user_assign.dart/user_assign_post_api.dart';
import 'package:onemoretour/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> userAssign({
  required String docId,
  required String baseUrl,
  required String collection, // "Cars" or "Guide"
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
    }, SetOptions(merge: true));

    userAssignPostApi.postData({'email': userEmail, 'ID': docId}, baseUrl);
  }

  navigatorKey.currentState?.pop();
}
