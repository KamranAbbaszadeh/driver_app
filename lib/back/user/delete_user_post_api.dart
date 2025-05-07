import 'dart:convert';

import 'package:http/http.dart' as http;

class DeleteUserPostApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/delete-user');
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
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
