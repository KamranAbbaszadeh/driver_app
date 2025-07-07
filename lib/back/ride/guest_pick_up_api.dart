// Sends a guest pickup notification to an external API endpoint.
// Used during ride progression to notify backend that the guest has been picked up.
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// A helper class that posts guest pickup events to the external Bubble API.
/// Sends data to the '/guest' endpoint with a bearer token and JSON payload.
class GuestPickUpApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Sends guest pickup data to the backend API.
  /// Returns `true` on success (status 200 or 201), otherwise logs the error and returns `false`.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/guest');
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
