// Handles sending user signup and update data to external APIs via HTTP POST requests.
// Two classes are defined for different endpoints: signup and 1st-phase update.

import 'package:http/http.dart' as http;
import 'dart:convert';

/// Sends user signup data to external API endpoint `/app-signup`.
/// Includes an authorization header and handles success/failure response.
class ApiService {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Sends the provided user data to the signup endpoint.
  /// Returns true if the request was successful (HTTP 200 or 201), otherwise false.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/app-signup');
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

/// Sends updated user data to a different external endpoint `/app-1phase`.
/// Used for submitting post-signup updates or phase-based information.
class ApiServiceUpdate {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Sends the provided updated user data to the 1st-phase endpoint.
  /// Returns true if the request was successful (HTTP 200 or 201), otherwise false.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/app-1phase');
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
