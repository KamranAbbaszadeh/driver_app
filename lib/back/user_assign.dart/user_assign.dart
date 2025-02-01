import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/back/user_assign.dart/user_assign_post_api.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> userAssign({
  required String docId,
  required String baseUrl,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final userEmail = FirebaseAuth.instance.currentUser?.email;
  final UserAssignPostApi userAssignPostApi = UserAssignPostApi();
  if (userId != null && userEmail != null) {
    await FirebaseFirestore.instance.collection('Cars').doc(docId).set({
      'Driver': userId,
    }, SetOptions(merge: true));
    userAssignPostApi.postData({'email': userEmail, 'ID': docId}, baseUrl);
  }
  navigatorKey.currentState?.pop();
}
