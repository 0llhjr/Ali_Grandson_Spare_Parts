// ============================================================
// email_service.dart — Email Sending via Google Apps Script
// ============================================================
// This service sends HTML emails by making an HTTP POST request
// to a Google Apps Script web app that acts as an email relay.
//
// Why Google Apps Script?
//   Flutter apps cannot send emails directly. A lightweight
//   Google Apps Script is deployed as a public web endpoint
//   that receives a JSON payload and calls Gmail's API.
//
// Configuration (stored in .env):
//   GOOGLE_SCRIPT_URL — the deployed script URL
//   EMAIL_TOKEN       — a shared secret to prevent unauthorized use
//   EMAIL_NAME        — the sender display name
//   ADMIN_EMAIL       — admin's email for store notifications
//
// Google Script returns HTTP 302 (redirect) on success, which the
// http package follows. Both 200 with "Success" and 302 are
// treated as successful sends.
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Sends emails through a Google Apps Script relay endpoint.
class EmailService {
  /// Posts an email request to the Google Apps Script endpoint.
  ///
  /// [recipientEmails] — a single email string or a List<String>.
  /// [subject]         — the email subject line.
  /// [htmlBody]        — the full HTML content of the email.
  ///
  /// Returns a map with `success` (bool) and `message` (String).
  Future<Map<String, dynamic>> sendGoogleEmail({
    required dynamic recipientEmails,
    required String subject,
    required String htmlBody,
  }) async {
    // Read configuration from environment variables loaded at startup.
    final googleScriptUrl = dotenv.env['GOOGLE_SCRIPT_URL'];
    final emailToken      = dotenv.env['EMAIL_TOKEN'];
    final senderName      = dotenv.env['EMAIL_NAME'];

    debugPrint("--- EmailService: Attempting to send email ---");

    // If the config is missing (e.g. .env not loaded), bail out early.
    if (googleScriptUrl == null || emailToken == null) {
      return {'success': false, 'message': 'Environment variables not loaded.'};
    }

    // Accept both a List<String> and a plain String for recipients.
    String formattedRecipients = recipientEmails is List<String>
        ? recipientEmails.join(',')
        : recipientEmails.toString();

    // Build the JSON body expected by the Google Apps Script.
    final Map<String, dynamic> payload = {
      "token": emailToken,
      "to": formattedRecipients,
      "subject": subject,
      "body": htmlBody,
      "name": senderName ?? "Ali Grandson Spare Parts",
      "attachments": [] // No file attachments
    };

    try {
      // Build a manual HTTP request so we can control redirect behaviour.
      // Google Script responds with HTTP 302 before the email is sent,
      // so we allow the http library to follow it.
      var request =
          http.Request('POST', Uri.parse(googleScriptUrl))
            ..headers.addAll({'Content-Type': 'application/json'})
            ..body = jsonEncode(payload)
            ..followRedirects = true;

      // Wait up to 25 seconds for a response (email sending can be slow).
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200 && response.body.contains("Success")) {
        debugPrint("Email sent successfully!");
        return {
          'success': true,
          'message': 'Email sent successfully',
          'recipients': formattedRecipients,
        };
      } else if (response.statusCode == 302) {
        // A 302 redirect means the script ran successfully but the http
        // client could not follow the final redirect. Treat as success
        // because emails have been confirmed to arrive in this case.
        debugPrint("Note: Received 302 Redirect. Script executed successfully.");
        return {
          'success': true,
          'message': 'Email sent (redirected)',
          'recipients': formattedRecipients,
        };
      } else {
        debugPrint(
            "Failed to send email. Status: ${response.statusCode}, Body: ${response.body}");
        return {
          'success': false,
          'message': 'Server returned ${response.statusCode}'
        };
      }
    } catch (e) {
      // Network errors (no internet, timeout, etc.).
      debugPrint("Network Error: ${e.toString()}");
      return {'success': false, 'message': 'Network Error: ${e.toString()}'};
    }
  }
}
