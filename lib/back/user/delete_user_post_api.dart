// Sends a request to delete a user via the Bubble API.
// Posts a JSON-encoded body with authorization headers to the '/delete-user' endpoint.
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A helper class to send user deletion requests to the external API.
/// Posts a JSON object to the '/delete-user' endpoint using HTTP POST.
class DeleteUserPostApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Sends the user deletion [data] to the backend API.
  /// Returns true if the request succeeds (HTTP 200 or 201), otherwise returns false.
  /// Catches and handles exceptions during the request.
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
