// Sends ride status updates (e.g., started, in-progress, completed) to an external API.
// Used to notify the backend of changes in the ride flow.
import 'package:http/http.dart' as http;
import 'dart:convert';

/// A helper class that posts ride status updates to the external Bubble API.
/// Sends data to the '/routestatus' endpoint with authorization and a JSON payload.

class RideFlowUpdateApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Posts ride status data to the backend API.
  /// Returns `true` on success (HTTP 200 or 201), otherwise `false`.
  /// Catches any exceptions and fails silently.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/routestatus');
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
