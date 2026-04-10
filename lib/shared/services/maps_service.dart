import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

/// Service for integrating with native maps applications
/// Handles platform-specific URL schemes and error cases
class MapsService {
  /// Opens native maps app with the specified coordinates and label
  /// 
  /// Uses platform-specific URL schemes:
  /// - Android: "geo:" scheme for Google Maps
  /// - iOS: "maps:" scheme for Apple Maps
  /// 
  /// [latitude] and [longitude] must be valid coordinates
  /// [label] is used for the map pin name
  Future<bool> openMaps({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    try {
      // Validate coordinates
      if (latitude < -90 || latitude > 90) {
        throw ArgumentError('Invalid latitude: $latitude. Must be between -90 and 90.');
      }
      if (longitude < -180 || longitude > 180) {
        throw ArgumentError('Invalid longitude: $longitude. Must be between -180 and 180.');
      }

      final Uri mapsUri;
      
      if (Platform.isAndroid) {
        // Android: Use geo: scheme for Google Maps
        // Format: geo:lat,lon?q=lat,lon(label)
        final encodedLabel = Uri.encodeComponent(label);
        mapsUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)');
      } else if (Platform.isIOS) {
        // iOS: Use maps: scheme for Apple Maps
        // Format: maps:?q=lat,lon&ll=lat,lon
        mapsUri = Uri.parse('maps:?q=$latitude,$longitude&ll=$latitude,$longitude');
      } else {
        // Fallback for other platforms (web, desktop)
        // Use Google Maps web URL
        final encodedLabel = Uri.encodeComponent(label);
        mapsUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedLabel');
      }

      // Check if the URL can be launched
      if (await canLaunchUrl(mapsUri)) {
        return await launchUrl(
          mapsUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        return false;
      }
    } catch (e) {
      // Log error for debugging
      print('MapsService: Error opening maps - $e');
      return false;
    }
  }

  /// Checks if maps functionality is available on the current platform
  /// 
  /// Returns true if the device can potentially open maps apps
  bool canLaunchMaps() {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Gets the appropriate error message for maps integration failures
  /// 
  /// Provides user-friendly error messages based on the platform
  String getErrorMessage() {
    if (Platform.isAndroid) {
      return 'No maps app found. Please install Google Maps from the Play Store.';
    } else if (Platform.isIOS) {
      return 'Unable to open maps app. Please check if Apple Maps is available.';
    } else {
      return 'Maps integration is not available on this platform.';
    }
  }

  /// Creates a shareable maps URL for the given coordinates
  /// 
  /// Useful as a fallback when native maps apps are not available
  String createShareableUrl({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    final encodedLabel = Uri.encodeComponent(label);
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$encodedLabel';
  }
}