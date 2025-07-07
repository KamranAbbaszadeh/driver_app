// Sends vehicle details to the Bubble API endpoint for registration or update.
// Posts a JSON payload with vehicle metadata using authentication headers.

import 'dart:convert';

import 'package:http/http.dart' as http;

/// A helper class to post vehicle details to the external API.
/// Sends a JSON-encoded body with proper headers to the '/addvehicle' endpoint.
class VehicleDetailsPostApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Sends vehicle [data] to the backend API using HTTP POST.
  /// Returns true on success (HTTP 200 or 201), otherwise false.
  /// Catches any exceptions and returns false in case of error.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/addvehicle');
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
