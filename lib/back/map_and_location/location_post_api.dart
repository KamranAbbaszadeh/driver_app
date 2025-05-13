import 'package:driver_app/back/api/firebase_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class LocationPostApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/carroad');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer a459ce6b65c0c7b2f91ee6767e7a06b1',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        logger.e(response.statusCode);
        return false;
      }
    } catch (e) {
      logger.e('Error: $e');
      return false;
    }
  }
}
