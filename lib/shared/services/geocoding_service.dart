import 'package:geocoding/geocoding.dart';

/// Result of geocoding operation
class LocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final String? error;
  
  const LocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.error,
  });
}

/// Service for converting addresses to coordinates and validation
class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  // Simple in-memory cache for coordinates
  final Map<String, LocationResult> _coordinateCache = {};

  /// Convert address to coordinates with caching
  Future<LocationResult> geocodeAddress(String address) async {
    try {
      // Check cache first
      final cached = getCachedCoordinates(address);
      if (cached != null) {
        return cached;
      }

      // Validate address has required components
      if (!_isValidAddress(address)) {
        return const LocationResult(
          success: false,
          error: 'Address must include street, city, and country',
        );
      }

      // Geocode the address
      final locations = await locationFromAddress(address);
      
      if (locations.isEmpty) {
        return const LocationResult(
          success: false,
          error: 'Address not found',
        );
      }

      final location = locations.first;
      final result = LocationResult(
        success: true,
        latitude: location.latitude,
        longitude: location.longitude,
        formattedAddress: address.trim(),
      );

      // Cache the result
      cacheCoordinates(address, location.latitude, location.longitude);

      return result;
    } catch (e) {
      print('Geocoding error: $e');
      return LocationResult(
        success: false,
        error: 'Failed to find location: ${e.toString()}',
      );
    }
  }

  /// Validate address has required components
  bool _isValidAddress(String address) {
    if (address.trim().isEmpty) return false;
    
    final parts = address.split(',');
    if (parts.length < 3) return false; // Need at least street, city, country
    
    // Check each part is not empty
    for (final part in parts) {
      if (part.trim().isEmpty) return false;
    }
    
    return true;
  }

  /// Cache coordinates for an address
  void cacheCoordinates(String address, double lat, double lon) {
    final key = address.toLowerCase().trim();
    _coordinateCache[key] = LocationResult(
      success: true,
      latitude: lat,
      longitude: lon,
      formattedAddress: address.trim(),
    );
  }

  /// Get cached coordinates for an address
  LocationResult? getCachedCoordinates(String address) {
    final key = address.toLowerCase().trim();
    return _coordinateCache[key];
  }

  /// Clear the coordinate cache
  void clearCache() {
    _coordinateCache.clear();
  }

  /// Get address suggestions (simplified - just returns the input for now)
  Future<List<String>> getAddressSuggestions(String query) async {
    // For MVP, just return the query as a suggestion
    // In a full implementation, this would use a places API
    if (query.trim().isEmpty) return [];
    return [query.trim()];
  }
}