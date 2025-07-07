// Service class for sending user assignment data to an external API endpoint.
// Handles HTTP POST requests with authorization and JSON-encoded body.
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Provides functionality to post user assignment data to the specified API endpoint.
/// Uses a fixed bearer token for authorization.
/// Returns true if the request succeeds (status code 200 or 201), false otherwise.
class UserAssignPostApi {
  /// Sends a POST request with [data] to the given [baseUrl].
  /// Returns a boolean indicating success or failure.
  /// Catches exceptions and returns false if any error occurs.
  Future<bool> postData(Map<String, dynamic> data, String baseUrl) async {
    final url = Uri.parse(baseUrl);
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
