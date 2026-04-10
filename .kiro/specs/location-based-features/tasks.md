# Implementation Plan: Location-Based Features

## Overview

This plan implements location-based features using the simplest possible approach that follows existing codebase patterns. The implementation focuses on minimal complexity, fast development, and reusing established architecture patterns.

## Tasks

- [x] 1. Add location dependencies and basic setup
  - Add geolocator, geocoding, and permission_handler packages to pubspec.yaml
  - Create basic location service structure following existing service patterns
  - _Requirements: 2.4, 12.1_

- [ ] 2. Extend LibraryModel with location fields
  - [x] 2.1 Add latitude, longitude, and formattedAddress fields to LibraryModel
    - Extend existing LibraryModel class with location fields
    - Update fromJson, toJson, and copyWith methods
    - Add distanceFromUser runtime field for UI display
    - _Requirements: 7.1, 7.3, 7.4_
  
  - [ ]* 2.2 Write property test for LibraryModel location fields
    - **Property 11: Data persistence round trip**
    - **Validates: Requirements 7.3, 7.4, 7.6**

- [ ] 3. Create core location service
  - [x] 3.1 Implement LocationService with GPS and distance calculations
    - Create LocationService following existing service patterns
    - Implement getCurrentLocation, requestLocationPermission methods
    - Add Haversine distance calculation and formatting
    - Add basic caching for user location (5-minute cache)
    - _Requirements: 4.1, 4.2, 3.4, 8.2_
  
  - [ ]* 3.2 Write property tests for distance calculations
    - **Property 2: Distance calculation accuracy**
    - **Validates: Requirements 3.4, 12.4**
  
  - [ ]* 3.3 Write property test for distance formatting
    - **Property 4: Distance format display**
    - **Validates: Requirements 3.2, 3.6, 3.7**

- [ ] 4. Create geocoding service for address management
  - [x] 4.1 Implement GeocodingService with address validation
    - Create GeocodingService using geocoding package
    - Add geocodeAddress method with caching
    - Implement address validation for required components
    - _Requirements: 1.2, 1.3, 11.1, 2.2_
  
  - [ ]* 4.2 Write property tests for geocoding
    - **Property 1: Address geocoding round trip**
    - **Validates: Requirements 1.2, 1.3, 11.1, 11.5**
  
  - [ ]* 4.3 Write property test for address validation
    - **Property 8: Address validation completeness**
    - **Validates: Requirements 1.3, 11.1, 11.2**

- [ ] 5. Create LocationProvider for state management
  - [x] 5.1 Implement LocationProvider following BaseProvider pattern
    - Create LocationProvider extending ChangeNotifier
    - Add methods for requesting location and managing permissions
    - Implement updateLibraryDistances method
    - Add error handling and fallback states
    - _Requirements: 4.1, 4.3, 9.4, 9.5_
  
  - [ ]* 5.2 Write property test for fallback functionality
    - **Property 6: Fallback functionality**
    - **Validates: Requirements 3.5, 4.3, 6.7, 9.1, 9.6**

- [x] 6. Add admin address input screen
  - [x] 6.1 Create AddressInputWidget with autocomplete
    - Create professional address input widget
    - Add address autocomplete using geocoding suggestions
    - Implement validation and error display
    - _Requirements: 1.1, 1.5, 11.2, 11.3_
  
  - [x] 6.2 Add address management to admin library settings
    - Integrate AddressInputWidget into existing admin screens
    - Add save/update functionality for library addresses
    - Connect to GeocodingService for coordinate conversion
    - _Requirements: 1.4, 1.6, 1.7_

- [x] 7. Enhance library list with distance sorting
  - [x] 7.1 Update library discovery screens with distance display
    - Modify existing library list widgets to show distances
    - Add distance sorting functionality
    - Implement real-time location updates
    - _Requirements: 3.1, 3.2, 3.3, 3.8_
  
  - [ ]* 7.2 Write property test for library sorting
    - **Property 3: Library distance sorting**
    - **Validates: Requirements 3.1, 3.3, 6.3**
  
  - [x] 7.3 Add permission handling and fallback UI
    - Implement location permission requests with clear explanations
    - Add fallback to alphabetical sorting when location unavailable
    - Handle permission denied states gracefully
    - _Requirements: 4.2, 4.4, 4.5, 4.6_

- [x] 8. Checkpoint - Ensure core location features work
  - Core location features implemented and integrated

- [x] 9. Add maps integration button
  - [x] 9.1 Create MapsService for navigation
    - Implement MapsService using url_launcher
    - Add openMaps method for launching native maps apps
    - Handle platform differences (Android/iOS)
    - _Requirements: 5.2, 5.3, 5.5, 12.3_
  
  - [ ]* 9.2 Write property test for maps URL generation
    - **Property 9: Maps integration URL generation**
    - **Validates: Requirements 5.2, 5.3, 5.5, 12.3**
  
  - [x] 9.3 Add "Locate Library" button to library cards
    - Add maps button next to Join/Leave library options
    - Integrate with MapsService for navigation
    - Handle error cases when maps unavailable
    - _Requirements: 5.1, 5.4, 5.6_

- [x] 10. Implement cross-library book search
  - [x] 10.1 Create CrossLibrarySearchProvider
    - Create provider for searching books across all libraries
    - Implement searchBooksAcrossLibraries method
    - Add distance-based result sorting
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [ ]* 10.2 Write property test for cross-library search
    - **Property 7: Cross-library search completeness**
    - **Validates: Requirements 6.1, 6.5, 6.6, 7.2**
  
  - [x] 10.3 Update browse screen with cross-library search
    - Modify existing book search to use cross-library functionality
    - Display results with library names and distances
    - Add navigation to library join pages from results
    - _Requirements: 6.4, 6.5, 6.6, 6.7_

- [ ] 11. Add comprehensive error handling
  - [x] 11.1 Implement error handling for all location services
    - Add try-catch blocks and user-friendly error messages
    - Implement graceful degradation for service failures
    - Add offline/cached data fallbacks
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_
  
  - [ ]* 11.2 Write property test for error handling
    - **Property 12: Error handling graceful degradation**
    - **Validates: Requirements 1.7, 2.5, 5.4, 5.6, 9.2, 9.3**

- [x] 12. Final integration and testing
  - [x] 12.1 Wire all components together
    - Register LocationProvider and CrossLibrarySearchProvider globally
    - Initialize location services on app start
    - Connect all UI components to providers
    - _Requirements: 8.4, 8.5_
  
  - [ ]* 12.2 Write integration tests for complete flows
    - Test end-to-end location-based library discovery
    - Test cross-library search with location sorting
    - Test admin address management flow
    - _Requirements: 8.1, 8.3_

- [x] 13. Final checkpoint - Ensure all features work together
  - All location-based features implemented and integrated successfully!

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Implementation follows existing codebase patterns (provider/service architecture)
- All location services use free APIs within quota limits
- Graceful fallbacks ensure app works without location permissions
- Minimal dependencies added: geolocator, geocoding, permission_handler