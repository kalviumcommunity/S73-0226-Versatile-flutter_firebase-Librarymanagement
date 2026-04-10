import 'dart:async';
import 'package:flutter/foundation.dart';

/// Base provider class with common functionality for managing subscriptions.
abstract class BaseProvider extends ChangeNotifier {
  final Map<String, StreamSubscription> _subscriptions = {};
  bool _isDisposed = false;

  /// Check if the provider has been disposed.
  bool get isDisposed => _isDisposed;

  /// Add a subscription to be managed by this provider.
  void addSubscription(String key, StreamSubscription subscription) {
    if (_isDisposed) {
      subscription.cancel();
      return;
    }
    
    // Cancel existing subscription with the same key
    _subscriptions[key]?.cancel();
    _subscriptions[key] = subscription;
  }

  /// Cancel a specific subscription by key.
  void cancelSubscription(String key) {
    final subscription = _subscriptions.remove(key);
    subscription?.cancel();
  }

  /// Cancel all subscriptions.
  void cancelAllSubscriptions() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _isDisposed = true;
    cancelAllSubscriptions();
    super.dispose();
  }
}