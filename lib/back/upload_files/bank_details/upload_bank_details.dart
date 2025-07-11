// Uploads bank details to Firestore and posts the same data to an external API.
// Handles special logic for 'Guide' role including form status updates.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/back/upload_files/bank_details/bank_details_post_api.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Uploads the provided [bankDetails] for the user identified by [userId] to Firestore.
/// If [role] is 'Guide', also updates application form status fields.
/// Then posts the data to an external API for further processing.
/// Shows a success message if the data is successfully posted.
Future<void> uploadBankDetails({
  required Map<String, dynamic> bankDetails,
  required String userId,
  required String role,
  required context,
}) async {
  if (role != 'Guide') {
    if (bankDetails.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Users').doc(userId).set({
        'Bank Details': bankDetails,
      }, SetOptions(merge: true));

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentUserEmail = user.email;
      if (currentUserEmail != null) {
        final BankDetailsPostApi bankDetailsPostApi = BankDetailsPostApi();
        await bankDetailsPostApi.postData({
          'User': currentUserEmail,
          'BankName': bankDetails['Bank Name'],
          'Code': bankDetails['Bank Code'],
          'MH': bankDetails['M.H'],
          'SWIFT': bankDetails['SWIFT'],
          'IBAN': bankDetails['IBAN'],
          'VAT': bankDetails['VAT'],
          'RegistrationAddress': bankDetails['Address'],
          'FINCode': bankDetails['FIN'],
        });
      }
    }
  } else {
    if (bankDetails.isNotEmpty) {
      await FirebaseFirestore.instance.collection('Users').doc(userId).set({
        'Bank Details': bankDetails,
        'Personal & Car Details Form': 'APPLICATION RECEIVED',
        'Personal & Car Details Decline': false,
      }, SetOptions(merge: true));

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final currentUserEmail = user.email;
      if (currentUserEmail != null) {
        final BankDetailsPostApi bankDetailsPostApi = BankDetailsPostApi();
        await bankDetailsPostApi.postData({
          'User': currentUserEmail,
          'BankName': bankDetails['Bank Name'],
          'Code': bankDetails['Bank Code'],
          'MH': bankDetails['M.H'],
          'SWIFT': bankDetails['SWIFT'],
          'IBAN': bankDetails['IBAN'],
          'VAT': bankDetails['VAT'],
          'RegistrationAddress': bankDetails['Address'],
          'FINCode': bankDetails['FIN'],
        });

      }
    }
  }
}
