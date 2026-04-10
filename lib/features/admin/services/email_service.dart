import '../../../shared/services/email_service.dart';

/// Handles sending access-token invitation emails.
///
/// Uses the shared [EmailService] under the hood.
/// Add more admin-specific email helpers here as needed.
class AccessTokenEmailService {
  static const String _templateId = 'template_nvmj67g';

  final EmailService _emailService;

  AccessTokenEmailService({EmailService? emailService})
      : _emailService = emailService ?? EmailService();

  /// Send an access-token invitation email.
  ///
  /// [recipientEmail] – the email address of the invitee.
  /// [accessCode]     – the 6-char one-time access code.
  /// [adminName]      – display name of the admin who generated the code.
  /// [libraryName]    – name of the library the invitee is joining.
  Future<void> send({
    required String recipientEmail,
    required String accessCode,
    required String adminName,
    required String libraryName,
  }) async {
    await _emailService.send(
      templateId: _templateId,
      toEmail: recipientEmail,
      templateParams: {
        'access_code': accessCode,
        'admin_name': adminName,
        'library_name': libraryName,
      },
    );
  }
}

