
// Sends user photo data to the Bubble API for profile update.
// Posts photo metadata as JSON to the '/app-userupdate' endpoint.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// A helper class to post user photo update data to an external API.
/// Sends a JSON-encoded body with authentication headers.
class PhotoPostApi {
    final String baseUrl =
      "https://tourism-86646.bubbleapps.io/version-test/api/1.1/wf";

  /// Sends a POST request with photo update data to the backend API.
  /// Returns true if the request succeeds (HTTP 200 or 201), otherwise false.
  /// Handles any exceptions during the request gracefully.
      Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/app-userupdate');
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




