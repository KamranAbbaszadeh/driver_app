// Sends certificate data to an external API endpoint.
// Used to upload user certification information for verification or compliance.
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A helper class to post certificate-related data to the Bubble API.
/// Sends JSON data to the '/app-new-cert' endpoint with authorization.
class CertificatePostApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Sends a POST request containing certificate [data] to the backend API.
  /// Returns true if the request is successful (HTTP 200 or 201), otherwise false.
  /// Catches and handles exceptions during the request.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/app-new-cert');
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
