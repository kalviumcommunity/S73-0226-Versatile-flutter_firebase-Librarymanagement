import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Result of a payment attempt.
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.paymentId,
    this.errorMessage,
  });
}

/// Handles Razorpay payment integration.
/// Each admin provides their own Razorpay key_id so payments
/// go directly to their account.
class PaymentService {
  Razorpay? _razorpay;
  Completer<PaymentResult>? _completer;

  /// Open Razorpay checkout for a membership payment.
  ///
  /// [razorpayKeyId] — admin's Razorpay API key (public key).
  /// [amountInr] — fee amount in INR (will be converted to paise).
  /// [libraryName] — shown in the checkout description.
  /// [userEmail] — prefilled email.
  /// [userPhone] — prefilled phone (optional).
  Future<PaymentResult> collectPayment({
    required String razorpayKeyId,
    required double amountInr,
    required String libraryName,
    required String userEmail,
    String? userName,
    String? userPhone,
  }) async {
    _completer = Completer<PaymentResult>();

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    final options = <String, dynamic>{
      'key': razorpayKeyId,
      'amount': (amountInr * 100).toInt(), // Razorpay uses paise
      'name': libraryName,
      'description': 'Library Membership Fee',
      'prefill': {
        'email': userEmail,
        if (userPhone != null && userPhone.isNotEmpty) 'contact': userPhone,
      },
      'theme': {
        'color': '#1E3A8A',
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _dispose();
      return PaymentResult(success: false, errorMessage: e.toString());
    }

    return _completer!.future;
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment success: ${response.paymentId}');
    _completer?.complete(PaymentResult(
      success: true,
      paymentId: response.paymentId,
    ));
    _dispose();
  }

  void _onPaymentError(PaymentFailureResponse response) {
    debugPrint('Payment error: ${response.code} - ${response.message}');
    _completer?.complete(PaymentResult(
      success: false,
      errorMessage: response.message ?? 'Payment failed',
    ));
    _dispose();
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
    // External wallet selected — payment not yet complete
    // Razorpay will follow up with success/error
  }

  void _dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
