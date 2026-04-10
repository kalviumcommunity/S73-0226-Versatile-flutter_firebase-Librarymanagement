import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A reusable service that sends emails via the EmailJS REST API.
///
/// Free tier: 200 emails/month.
/// Works from mobile apps (non-browser) when the private key is provided
/// and "Allow non-browser applications" is enabled in the EmailJS dashboard.
class EmailService {
  // ── EmailJS credentials ──
  static const String _serviceId = 'service_q8ks1pi';
  static const String _publicKey = 'TkTkBL_JhOWBhOhCU';
  static const String _privateKey = 'llYEqdHYInJrE8XqdmnxH';

  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Send an email using a specific EmailJS template.
  ///
  /// [templateId]     – the EmailJS template ID to use.
  /// [toEmail]        – recipient email address.
  /// [templateParams] – key-value pairs that map to {{variables}} in the template.
  Future<void> send({
    required String templateId,
    required String toEmail,
    required Map<String, dynamic> templateParams,
  }) async {
    final payload = {
      'service_id': _serviceId,
      'template_id': templateId,
      'user_id': _publicKey,
      'accessToken': _privateKey,
      'template_params': {
        'to_email': toEmail,
        ...templateParams,
      },
    };

    debugPrint('[EmailService] Sending to: $toEmail');
    debugPrint('[EmailService] Template: $templateId');

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost',
      },
      body: jsonEncode(payload),
    );

    debugPrint('[EmailService] Response status: ${response.statusCode}');
    debugPrint('[EmailService] Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw EmailSendException(
        statusCode: response.statusCode,
        message: response.body,
      );
    }
  }
}

/// Exception thrown when an email fails to send.
class EmailSendException implements Exception {
  final int statusCode;
  final String message;

  EmailSendException({required this.statusCode, required this.message});

  @override
  String toString() => 'EmailSendException($statusCode): $message';
}
