// Handles sending chat message data to an external API endpoint using HTTP POST.
// Includes authorization and JSON encoding, and returns success status.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// A helper class to send chat messages to the remote Bubble API.
/// Uses a predefined base URL and bearer token for authentication.
class MessageSendApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Sends a POST request to the `/chat` endpoint with the given data payload.
  /// Returns `true` if the response is successful (200 or 201), otherwise `false`.
  /// Catches and handles any exceptions that occur during the request.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/chat');
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
