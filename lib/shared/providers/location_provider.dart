import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/location_service.dart';
import '../../features/library/models/library_model.dart';

/// Provider for managing location state and library distance calculations
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _userLocation;
  bool _hasLocationPermission = false;
  bool _isLoadingLocation = false;
  String? _error;
  Timer? _locationUpdateTimer;

  // Getters
  Position? get userLocation => _userLocation;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get error => _error;

  LocationProvider() {
    // Automatically request location when provider is created
    _initializeLocation();
  }

  /// Initialize location services automatically
  Future<void> _initializeLocation() async {
    await requestLocation();
    
    // Set up periodic location updates every 2 minutes
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updateLocationSilently();
    });
  }

  /// Update location silently without showing loading state
  Future<void> _updateLocationSilently() async {
    if (!_hasLocationPermission) return;
    
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        _userLocation = location;
        notifyListeners(); // This will trigger UI updates for distance sorting
      }
    } catch (e) {
      // Silently handle errors for background updates
      print('Background location update failed: $e');
    }
  }
  /// Request location permission and get current location
  Future<void> requestLocation() async {
    if (_isLoadingLocation) return;

    _isLoadingLocation = true;
    _error = null;
    notifyListeners();

    try {
      // Request permission
      final hasPermission = await _locationService.requestLocationPermission();
      _hasLocationPermission = hasPermission;

      if (hasPermission) {
        // Get current location
        final location = await _locationService.getCurrentLocation();
        _userLocation = location;
        
        if (location == null) {
          _error = 'Unable to get your location. Please check GPS settings.';
        }
      } else {
        _error = 'Location permission denied. Libraries will be sorted alphabetically.';
      }
    } catch (e) {
      _error = 'Error getting location: ${e.toString()}';
      print('LocationProvider error: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Update library distances based on user location
  void updateLibraryDistances(List<LibraryModel> libraries) {
    if (_userLocation == null) return;

    for (final library in libraries) {
      if (library.latitude != null && library.longitude != null) {
        final distance = _locationService.calculateDistance(
          _userLocation!.latitude,
          _userLocation!.longitude,
          library.latitude!,
          library.longitude!,
        );
        library.distanceFromUser = distance;
      }
    }
  }

  /// Get libraries sorted by distance (nearest first)
  List<LibraryModel> sortLibrariesByDistance(List<LibraryModel> libraries) {
    // Update distances first
    updateLibraryDistances(libraries);

    // Create a copy to avoid modifying the original list
    final sortedLibraries = List<LibraryModel>.from(libraries);

    if (_userLocation != null) {
      // Sort by distance (libraries without coordinates go to end)
      sortedLibraries.sort((a, b) {
        final aDistance = a.distanceFromUser;
        final bDistance = b.distanceFromUser;

        if (aDistance == null && bDistance == null) return 0;
        if (aDistance == null) return 1;
        if (bDistance == null) return -1;

        return aDistance.compareTo(bDistance);
      });
    } else {
      // Fallback to alphabetical sorting when no location
      sortedLibraries.sort((a, b) => a.name.compareTo(b.name));
    }

    return sortedLibraries;
  }

  /// Format distance for display
  String formatDistance(double? distanceKm) {
    if (distanceKm == null) return '';
    return _locationService.formatDistance(distanceKm);
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return _locationService.calculateDistance(lat1, lon1, lat2, lon2);
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if location services are available
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get cached location without requesting new one
  Position? getCachedLocation() {
    return _locationService.getCachedLocation();
  }

  /// Clear cached location data
  void clearLocationCache() {
    _locationService.clearCache();
    _userLocation = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }
}