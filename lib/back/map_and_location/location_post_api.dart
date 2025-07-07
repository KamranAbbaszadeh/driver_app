// Sends location data to an external API endpoint for tracking vehicle movement.
// Uses HTTP POST with authorization and handles response validation and error logging.
import 'package:onemoretour/back/api/firebase_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


/// Service class for sending location updates to an external Bubble API.
/// Sends data to the '/carroad' endpoint with proper headers and JSON formatting.
class LocationPostApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Posts location data to the backend.
  /// Returns true if the request is successful (HTTP 200 or 201), otherwise logs the error and returns false.
  /// Uses a static bearer token and encodes the payload as JSON.
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
