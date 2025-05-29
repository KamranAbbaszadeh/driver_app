import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onemoretour/front/auth/forms/contracts/contract_body_driver.dart';
import 'package:onemoretour/front/auth/forms/contracts/contract_body_guide.dart';
import 'package:onemoretour/front/intro/welcome_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class ContractSignForm extends StatefulWidget {
  const ContractSignForm({super.key});

  @override
  State<ContractSignForm> createState() => _ContractSignFormState();
}

class _ContractSignFormState extends State<ContractSignForm> {
  final user = FirebaseAuth.instance.currentUser;
  late String userId;
  @override
  void initState() {
    super.initState();
    if (user == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    } else {
      userId = user!.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    GlobalKey<SfSignaturePadState> signaturePadKey = GlobalKey();
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    initializeDateFormatting('az', null);
    DateTime now = DateTime.now();

    var formatter = DateFormat('dd MMMM yyyy', 'az');

    String formattedDate = formatter.format(now);

    formattedDate = formattedDate.replaceFirst(
      formattedDate.split(' ')[1],
      formattedDate.split(' ')[1][0].toUpperCase() +
          formattedDate.split(' ')[1].substring(1),
    );
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("No data found"));
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;

        String firstName = userData['First Name'];
        String lastName = userData['Last Name'];
        String fathersName = userData['Father\'s Name'];
        String role = userData['Role'];

        String fullName = '$lastName, $firstName, $fathersName';

        String address = userData['Bank Details']['Address'] ?? '';
        String finCode = userData['Bank Details']['FIN'] ?? '';
        String vatNum = userData['Bank Details']['VAT'] ?? '';
        String bankName = userData['Bank Details']['Bank Name'] ?? '';
        String bankCode = userData['Bank Details']['Bank Code'] ?? '';
        String mH = userData['Bank Details']['M.H'] ?? '';
        String swift = userData['Bank Details']['SWIFT'] ?? '';
        String iban = userData['Bank Details']['IBAN'] ?? '';

        return Scaffold(
          backgroundColor: darkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: darkMode ? Colors.black : Colors.white,
            surfaceTintColor: darkMode ? Colors.black : Colors.white,
            centerTitle: true,
            leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              hoverColor: Colors.transparent,
              icon: Icon(
                Icons.arrow_circle_left_rounded,
                size: width * 0.1,
                color: Colors.grey.shade400,
              ),
            ),
            toolbarHeight: height * 0.1,
            title: Text(
              'Müqavilə',
              overflow: TextOverflow.visible,
              softWrap: true,
              style: TextStyle(
                fontSize: width * 0.066,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body:
              role == 'Guide'
                  ? ContractBodyGuide(
                    address: address,
                    bankCode: bankCode,
                    bankName: bankName,
                    finCode: finCode,
                    formattedDate: formattedDate,
                    fullName: fullName,
                    iban: iban,
                    mH: mH,
                    swift: swift,
                    vatNum: vatNum,
                    signaturePadKey: signaturePadKey,
                  )
                  : ContractBodyDriver(
                    address: address,
                    bankCode: bankCode,
                    bankName: bankName,
                    finCode: finCode,
                    formattedDate: formattedDate,
                    fullName: fullName,
                    iban: iban,
                    mH: mH,
                    swift: swift,
                    vatNum: vatNum,
                    signaturePadKey: signaturePadKey,
                  ),
        );
      },
    );
  }
}
