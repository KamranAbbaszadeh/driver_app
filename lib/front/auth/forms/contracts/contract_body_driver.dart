import 'dart:typed_data';

import 'package:driver_app/back/upload_files/upload_signature/upload_signature_save.dart';
import 'package:driver_app/front/auth/forms/contracts/build_section_tile.dart';
import 'package:driver_app/front/auth/forms/contracts/build_subsection.dart';
import 'package:driver_app/front/auth/forms/contracts/save_signature.dart';
import 'package:driver_app/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';

class ContractBodyDriver extends StatelessWidget {
  final String formattedDate;
  final String finCode;
  final String fullName;
  final String address;
  final String vatNum;
  final String bankName;
  final String bankCode;
  final String mH;
  final String swift;
  final String iban;
  final GlobalKey<SfSignaturePadState> signaturePadKey;

  const ContractBodyDriver({
    super.key,
    required this.address,
    required this.bankCode,
    required this.bankName,
    required this.finCode,
    required this.formattedDate,
    required this.fullName,
    required this.iban,
    required this.mH,
    required this.swift,
    required this.vatNum,
    required this.signaturePadKey,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    Uint8List? signBytes;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sürücü ilə Səyahət Agentliyi arasında Müqavilə №',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: height * 0.023),
            Text(
              'Müqavilə Şərtləri',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.011),
            Text(
              'Bu müqavilə $formattedDate il tarixində bağlanmışdır:',
              style: TextStyle(fontSize: width * 0.04),
            ),
            SizedBox(height: height * 0.011),
            buildSectionTitle('Tərəflər', width),
            SizedBox(height: height * 0.011),
            RichText(
              text: TextSpan(
                text: 'Tərəf 1: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
                children: [
                  TextSpan(
                    text:
                        'Bakı şəhəri, Nəsimi rayonu, Bülbül pr. 79B ünvanda qeydiyyatdan olan 1403258191 VÖEN-i ilə "START TRAVEL" MMC, bundan sonra “Agentlik” adlandırılacaq.',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.011),
            RichText(
              text: TextSpan(
                text: 'Tərəf 2: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.04,
                ),
                children: [
                  TextSpan(
                    text:
                        '$address ünvanda qeydiyyatda olan VÖEN-li, $finCode Fərdi İdentifikasiya Nömrəli $fullName bundan sonra “Sürücü” adlandırılacaq.',
                    style: TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.023),
            buildSectionTitle('1. Tərəflərin Öhdəlikləri', width),
            SizedBox(height: height * 0.011),
            buildSubsection(
              '1.1	Agentliyin Öhdəlikləri:',
              '''
•	Sürücünü, ona həvalə edilən tur paketlərin, əvvəlcədən detalları ilə, aydın marşrutlarla və müştəri məlumatları ilə təmin etmək.
•	Marşrut və ya müştəri tələblərində ki dəyişikliklər barədə vaxtında məlumat vermək.
•	Ödənişləri razılaşdırılmış şərtlərə uyğun olaraq həyata keçirmək.
            ''',
              height,
              width,
            ),
            buildSubsection(
              '1.2	Sürücünün Öhdəlikləri:',
              '''
•	Təhlükəsiz və vaxtında nəqliyyat xidmətləri göstərmək, təyin edilmiş marşruta riayət etmək.
•	Avtomobilin təmiz, texniki baxımdan saz və təhlükəsizlik tədbirləri ilə təchiz olunmuş vəziyyətdə olmasını təmin etmək.
•	Yerli yol hərəkəti qaydalarına riayət etmək və sərnişinlərin təhlükəsizliyini prioritet etmək.
•	Hər zaman şəxsi gigiyena qaydalarına əməl etmək və səliqəli, hörmət doğuran görünüşə sahib olmaq.
•	Agentliyin nüfuzuna zərər gətirə biləcək hərəkətlərdən çəkinmək.
            ''',
              height,
              width,
            ),
            SizedBox(height: height * 0.023),
            buildSubsection(
              '2. Xidmət Standartları',
              '''
2.1	Sürücü təyin edilmiş marşruta və cədvələ riayət etməlidir, turun əvvəlcədən razılaşdırılmış müddətə uyğun davam etməsini təmin etməlidir.
2.2	Müştərilərə qarşı hər hansı hörmətsiz davranış, narahatedici hərəkət, təcavüz və ya ayrı-seçkilik qəti şəkildə qadağandır.
2.3	Sürücü müştərilərlə ünsiyyətdə olmaq üçün baza səviyyəsində dil biliyinə malik olmalıdır.
2.4	Sürücü hər zaman nəzakətli, peşəkar və köməkçi davranış nümayiş etdirməlidir.
''',
              height,
              width,
            ),

            SizedBox(height: height * 0.023),
            buildSubsection(
              '3. Uyğunsuzluğa Görə Cəzalar',
              '''
3.1	Sürücü bu müqavilədə göstərilən xidmət standartlarına və öhdəliklərə riayət etmədikdə:
•	Həmin günə görə ödəniş həyata keçirilməyəcəkdir.
•	Agentlik müqaviləni dərhal ləğv etmək hüququnu özündə saxlayır.
''',
              height,
              width,
            ),

            SizedBox(height: height * 0.023),
            buildSubsection(
              '4. Tariflər üçün Əlavə',
              '''3.1	Sürücü Əlavə 1-də göstərilən tariflərlə xidmət göstərməyi qəbul edir.
3.2	Razılaşdırılmış tariflərdə dəyişiklik etmək istəyən tərəf digər tərəfə yazılı məlumat verməlidir. Əks halda, əvvəlki tariflər qüvvədə qalacaqdır.
''',
              height,
              width,
            ),

            SizedBox(height: height * 0.023),
            buildSubsection(
              '5. Ödəniş Şərtləri',
              '''5.1	Hesab-faktura təqdim edildikdən sonra 5 gün ərzində ödənişlər həyata keçiriləcəkdir.
5.2	Hesab-fakturalarla bağlı mübahisələr 5 gün ərzində həll edilməlidir.
''',
              height,
              width,
            ),
            SizedBox(height: height * 0.023),
            buildSubsection(
              '6. Bronlaşdırma və Ləğvetmə Qaydaları',
              '''
6.1	Bronlaşdırma Qaydaları:

•	Agentlik, xidmət üçün tarix, saat, marşrut, qonaq sayı və hər hansı xüsusi tələblər daxil olmaqla, bron məlumatlarını ən az [X] saat/gün əvvəl Sürücü təqdim etməlidir.
•	Sürücü bronu aldıqdan sonra [X] saat ərzində təsdiqləməlidir.


6.2	Ləğvetmə Qaydaları:

•	Agentlik tərəfindən xidmətin ləğvi ən az [X] saat/gün əvvəl yazılı şəkildə bildirilməlidir.
•	Razılaşdırılmış müddət ərzində edilən ləğvlər üçün hər hansı ödəniş tətbiq olunmayacaq.
•	Gec ləğv hallarında (müəyyən edilmiş [X] saat/gün ərzində) Agentlik, qarşılıqlı razılaşma ilə bağışlanmadığı halda, [faiz/məbləğ] məbləğində cərimə ödəməyi qəbul edir.
•	Sürücü təsdiqlənmiş bronu gözlənilməz hallara görə yerinə yetirə bilmədikdə, dərhal Agentliyi məlumatlandırmalı və əsaslı səbəb göstərməlidir.
            ''',
              height,
              width,
            ),

            SizedBox(height: height * 0.023),
            buildSubsection(
              '7. Müqavilənin Müddəti',
              '''7.3	Bu müqavilə 31 Dekabr 2025-ci il tarixində başa çatacaqdır.
7.4	Hər hansı bir tərəf müqavilənin ləğv edilməsini yazılı şəkildə bildirmədikdə, müqavilə avtomatik olaraq növbəti il üçün uzadılacaqdır.
7.5	Müqavilənin ləğvi üçün bir tərəf digər tərəfə yazılı məlumat təqdim etməlidir. Yazılı bildiriş olmadıqda müqavilə qüvvədə qalacaqdır.
''',
              height,
              width,
            ),
            SizedBox(height: height * 0.023),
            buildSubsection(
              '8. Məxfilik',
              '''8.1	Sürücü, Agentlik və ya müştərilər barədə hər hansı məxfi məlumatı üçüncü tərəflərə açıqlamamalıdır.
8.2	Agentlik və ya onun tərəfdaşları ilə bağlı məxfi məlumatların paylaşılması halında, Agentlik Sürücünü məhkəməyə verə bilər.
''',
              height,
              width,
            ),
            SizedBox(height: height * 0.023),
            buildSubsection(
              '9. Fors-major Halları',
              '''9.1	Hər iki tərəf təbii fəlakət, tətil və ya pandemiya kimi hallardan irəli gələn gecikmə və ya uğursuzluq üçün məsuliyyət daşımır.
9.2	Fors-major hallarında təsirlənmiş tərəf dərhal digər tərəfə məlumat verməli və vəziyyəti təsdiqləyən sübutlar təqdim etməlidir.
9.3	Hər iki tərəf öhdəliklərin mümkün olan alternativ yollarla yerinə yetirilməsini müzakirə edəcəkdir.
''',
              height,
              width,
            ),
            SizedBox(height: height * 0.035),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Bank Rekvizitləri:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: height * 0.046),
                Text(
                  '"START TRAVEL" MMC',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'VÖEN: 1403258191',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'Bank: Kapital Bank ASC Mərkəz filialı',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'Kod: 200026',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'M.H: AZ37NABZ01350100000000001944',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'SWIFT: AIIBAZ2XXXX',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'IBAN: AZ28AIIB40060019440437962102',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.046),
                Text(
                  'Agentliyin Nümayəndəsi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.046),
                Container(
                  width: width,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.004),
                ),
                SizedBox(height: height * 0.023),
                Text(
                  'Tarix və Möhür:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.046),
                Container(
                  width: width,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.004),
                ),

                SizedBox(height: height * 0.046),
                Text(
                  'Sürücünün Tam Adı: $fullName',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'VÖEN: $vatNum',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'Bank: $bankName',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'Kod: $bankCode',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text('M.H: $mH', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: height * 0.011),
                Text(
                  'SWIFT: $swift',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text(
                  'IBAN: $iban',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: height * 0.011),
                Text('Sürücü:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: height * 0.011),
                Container(
                  width: width,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.004),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '*Zəhmət olmasa imzanızı çəkin',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          IconButton(
                            onPressed: () {
                              signaturePadKey.currentState?.clear();
                            },
                            icon: Icon(Icons.restart_alt_rounded),
                          ),
                        ],
                      ),
                      SizedBox(height: height * 0.005),
                      Container(
                        width: width,
                        height: height * 0.352,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: SfSignaturePad(
                          minimumStrokeWidth: width * 0.002,
                          maximumStrokeWidth: width * 0.007,
                          key: signaturePadKey,
                          strokeColor: Colors.blueAccent,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.023),
                Text('Tarix:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: height * 0.011),
                Container(
                  width: width,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: darkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(vertical: height * 0.004),
                  child: Text(
                    formattedDate,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.035),
            GestureDetector(
              onTap: () async {
                final userID = FirebaseAuth.instance.currentUser?.uid;
                if (userID != null) {
                  signBytes = await saveSignature(
                    signaturePadKey: signaturePadKey,
                    userID: userID,
                  );
                }
                if (signBytes != null) {
                  await uploadSignatureAndSave(signBytes!);
                  navigatorKey.currentState?.pushNamed('/waiting_screen');
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      darkMode
                          ? Color.fromARGB(255, 52, 168, 235)
                          : Color.fromARGB(177, 0, 134, 179),
                  borderRadius: BorderRadius.circular(width * 0.019),
                ),
                width: width,
                height: height * 0.058,
                child: Center(
                  child: Text(
                    'Imzala',
                    style: TextStyle(
                      color:
                          darkMode
                              ? const Color.fromARGB(132, 0, 0, 0)
                              : const Color.fromARGB(187, 255, 255, 255),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
