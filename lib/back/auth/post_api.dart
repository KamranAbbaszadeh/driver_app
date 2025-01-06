import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl =
      "https://tourism-86646.bubbleapps.io/version-test/api/1.1/wf";

  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/app-signup');
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
        print('Failed to post data: ${response.statusCode}');
        print('Error message: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }
}
