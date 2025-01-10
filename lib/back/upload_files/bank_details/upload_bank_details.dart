import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadBankDetails({
  required Map<String, dynamic> bankDetails,
  required String userId,
}) async {
  if (bankDetails.isNotEmpty) {
    await FirebaseFirestore.instance.collection('Users').doc(userId).set({
      'Bank Details': bankDetails,
    }, SetOptions(merge: true));
  }
}
