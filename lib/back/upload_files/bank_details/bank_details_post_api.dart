// Sends bank account details to an external API endpoint.
// This API is used to register or update driver bank information for payout purposes.
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A helper class to post bank account details to the external Bubble API.
/// Sends the data as JSON with appropriate authentication headers.
class BankDetailsPostApi {
  final String baseUrl = "https://onemoretour.com/version-test/api/1.1/wf";

  /// Posts the provided [data] to the /addbankaccount API endpoint.
  /// Returns true on success (HTTP 200 or 201), false otherwise.
  /// Catches any exceptions during the request process.
  Future<bool> postData(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/addbankaccount');
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
