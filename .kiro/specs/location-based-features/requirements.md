# Requirements Document

## Introduction

This document specifies the requirements for implementing location-based features in the library management application. The system will enable library administrators to manage physical addresses, allow readers to discover nearby libraries, provide maps integration for navigation, and enable cross-library book search with distance-based sorting. All location services must be implemented using free APIs and services to maintain zero ongoing operational costs.

**CRITICAL IMPLEMENTATION NOTE**: This document is designed to prevent all implementation mistakes and stubborn errors. Every requirement includes specific technical details, exact error messages, precise validation rules, and comprehensive edge case handling. Developers MUST follow these specifications exactly to avoid common pitfalls.

## Glossary

- **Library_Admin**: A user with administrative privileges for a specific library who can modify library address and settings
- **Reader**: A user who can browse and borrow books from libraries and view location-based features
- **Location_Service**: The system component that handles GPS coordinates, distance calculations, and location caching (lib/shared/services/location_service.dart)
- **Address_Manager**: The system component that manages library physical addresses with validation and geocoding (AddressInputWidget)
- **Library_Discovery**: The system component that sorts and displays libraries by distance from user location
- **Maps_Integration**: The system component that interfaces with native maps applications using url_launcher
- **Cross_Library_Search**: The system component that searches books across all libraries with distance-based sorting
- **Geocoding_Service**: External service that converts addresses to GPS coordinates using Google Geocoding API (lib/shared/services/geocoding_service.dart)
- **Distance_Calculator**: Component that calculates distances using Haversine formula via Geolocator.distanceBetween()
- **Permission_Handler**: Component that manages location permissions using permission_handler package
- **Native_Maps**: Device's default maps application (Google Maps on Android, Apple Maps on iOS)
- **LocationProvider**: State management provider extending BaseProvider for location operations (lib/shared/providers/location_provider.dart)
- **LibraryModel**: Data model with location fields: latitude, longitude, formattedAddress, distanceFromUser
- **LocationResult**: Result object from geocoding operations with success/error states
- **BaseProvider**: Abstract provider class with subscription management for consistent architecture

## Requirements

### Requirement 1: Library Address Management with Professional Autocomplete

**User Story:** As a library admin, I want to set and update my library's physical address with professional autocomplete functionality, so that readers can find and navigate to my library accurately.

#### Acceptance Criteria

1. **Address Input Interface Requirements**
   - THE AddressInputWidget SHALL provide a multi-line TextFormField with exactly 2 maxLines
   - THE AddressInputWidget SHALL display label text "Library Address" 
   - THE AddressInputWidget SHALL show hint text "Enter complete address with street, city, country"
   - THE AddressInputWidget SHALL include a location_on prefixIcon
   - THE AddressInputWidget SHALL use OutlineInputBorder with AppDimens.radiusMd borderRadius
   - THE AddressInputWidget SHALL show a loading indicator (CircularProgressIndicator with strokeWidth: 2) in suffixIcon during validation
   - THE AddressInputWidget SHALL show a green check_circle icon when address is valid
   - THE AddressInputWidget SHALL display error messages in red text below the input field

2. **Address Validation Requirements**
   - THE Address_Manager SHALL validate that addresses contain at least 3 comma-separated parts (street, city, country)
   - THE Address_Manager SHALL reject addresses where any comma-separated part is empty or whitespace-only
   - THE Address_Manager SHALL trim whitespace from all address components before validation
   - THE Address_Manager SHALL set _isValid to true only when address has 3+ non-empty parts
   - THE Address_Manager SHALL clear _errorMessage and set _isValid to false on every text change
   - THE Address_Manager SHALL prevent saving when _isValid is false or _isValidating is true

3. **Geocoding Integration Requirements**
   - THE Geocoding_Service SHALL use the geocoding package's locationFromAddress() method
   - THE Geocoding_Service SHALL implement caching using Map<String, LocationResult> with lowercase trimmed keys
   - THE Geocoding_Service SHALL check cache before making API calls using getCachedCoordinates()
   - THE Geocoding_Service SHALL return LocationResult objects with success, latitude, longitude, formattedAddress, and error fields
   - THE Geocoding_Service SHALL handle empty location results with error "Address not found"
   - THE Geocoding_Service SHALL catch all exceptions and return LocationResult with success: false and descriptive error message

4. **Address Saving Process Requirements**
   - THE Address_Manager SHALL set _isValidating to true and _errorMessage to null before geocoding
   - THE Address_Manager SHALL call _geocodingService.geocodeAddress() with trimmed address text
   - THE Address_Manager SHALL verify LocationResult.success is true and coordinates are not null before saving
   - THE Address_Manager SHALL call onAddressSaved callback with (formattedAddress, latitude, longitude) on success
   - THE Address_Manager SHALL show green SnackBar with text "Address saved successfully!" on successful save
   - THE Address_Manager SHALL set _errorMessage and _isValid to false on geocoding failure
   - THE Address_Manager SHALL set _isValidating to false in finally block to ensure UI state reset

5. **Error Handling Requirements**
   - WHEN geocoding returns success: false, THE Address_Manager SHALL display result.error in _errorMessage field
   - WHEN geocoding throws exception, THE Address_Manager SHALL display "Error validating address: ${e.toString()}" 
   - WHEN address has fewer than 3 parts, THE Address_Manager SHALL not attempt geocoding
   - WHEN any address part is empty, THE Address_Manager SHALL not set _isValid to true
   - THE Address_Manager SHALL handle mounted check before calling setState after async operations

6. **UI State Management Requirements**
   - THE Address_Manager SHALL disable save button when _isValid is false or _isValidating is true
   - THE Address_Manager SHALL show "Validating..." button text during _isValidating state
   - THE Address_Manager SHALL show "Save Address" button text in normal state
   - THE Address_Manager SHALL display loading spinner in button during _isValidating
   - THE Address_Manager SHALL use AppColors.primary for button background and white foreground
   - THE Address_Manager SHALL include info container with blue background explaining address format requirements

7. **Data Persistence Requirements**
   - THE Library model SHALL store latitude as double? field in Firestore
   - THE Library model SHALL store longitude as double? field in Firestore  
   - THE Library model SHALL store formattedAddress as String? field in Firestore
   - THE Library model SHALL include these fields in toJson() method with null checks
   - THE Library model SHALL parse these fields in fromJson() method with null safety
   - THE Library model SHALL include these fields in copyWith() method for immutable updates

### Requirement 2: Free API Usage Compliance and Caching Strategy

**User Story:** As a system operator, I want to ensure all location services remain free and efficient, so that the application has no ongoing operational costs and performs well.

#### Acceptance Criteria

1. **Google Geocoding API Compliance**
   - THE Geocoding_Service SHALL use only the free geocoding package which provides 40,000 free requests per month
   - THE Geocoding_Service SHALL implement permanent caching using Map<String, LocationResult> to minimize API calls
   - THE Geocoding_Service SHALL use lowercase trimmed address as cache key to maximize cache hits
   - THE Geocoding_Service SHALL never make duplicate API calls for the same address
   - THE Geocoding_Service SHALL log API usage for monitoring (print statements acceptable for MVP)

2. **Location Caching Strategy**
   - THE Location_Service SHALL cache user location for exactly 5 minutes using _cacheTimeout = Duration(minutes: 5)
   - THE Location_Service SHALL store _cachedLocation as Position? and _cacheTime as DateTime?
   - THE Location_Service SHALL check cache validity using DateTime.now().difference(_cacheTime!).compareTo(_cacheTimeout) < 0
   - THE Location_Service SHALL return cached location immediately if valid, avoiding GPS calls
   - THE Location_Service SHALL clear cache when clearCache() is called

3. **Package Dependencies**
   - THE Location_Service SHALL use only these free packages: geolocator, geocoding, permission_handler, url_launcher
   - THE Location_Service SHALL NOT use any paid location services or APIs
   - THE Location_Service SHALL use Geolocator.distanceBetween() for distance calculations (no custom Haversine implementation needed)
   - THE Location_Service SHALL use Geolocator.getCurrentPosition() with desiredAccuracy: LocationAccuracy.medium

4. **Performance Optimization**
   - THE Distance_Calculator SHALL cache distance calculations in LibraryModel.distanceFromUser field
   - THE Location_Service SHALL set timeLimit: Duration(seconds: 10) for getCurrentPosition to prevent hanging
   - THE Geocoding_Service SHALL implement clearCache() method for testing and memory management
   - THE Location_Service SHALL provide getCachedLocation() method for immediate access without async calls

5. **Error Recovery and Fallbacks**
   - WHEN API quota approaches limits, THE Location_Service SHALL log warnings using print() statements
   - WHEN geocoding fails, THE Address_Manager SHALL allow manual coordinate entry as fallback (future enhancement)
   - WHEN location services fail, THE Library_Discovery SHALL fall back to alphabetical sorting
   - THE Location_Service SHALL handle all exceptions gracefully without crashing the app

### Requirement 3: Reader Location-Based Library Discovery

**User Story:** As a reader, I want to see libraries sorted by distance from my location with clear distance indicators, so that I can easily find the nearest libraries to visit.

#### Acceptance Criteria

1. **Distance Calculation Requirements**
   - THE LocationProvider SHALL extend BaseProvider for consistent architecture
   - THE LocationProvider SHALL use Geolocator.distanceBetween(lat1, lon1, lat2, lon2) for distance calculations
   - THE LocationProvider SHALL convert distance from meters to kilometers by dividing by 1000
   - THE LocationProvider SHALL store calculated distance in LibraryModel.distanceFromUser field
   - THE LocationProvider SHALL recalculate distances when user location changes

2. **Distance Display Format Requirements**
   - THE Location_Service SHALL format distances under 1000m as "${meters}m away" (e.g., "250m away")
   - THE Location_Service SHALL format distances 1000m+ as "${km}km away" with 1 decimal place (e.g., "2.5km away")
   - THE Location_Service SHALL use formatDistance() method returning String for consistent formatting
   - THE LocationProvider SHALL provide formatDistance(double? distanceKm) wrapper method
   - THE Library list UI SHALL display formatted distance next to library name

3. **Sorting Algorithm Requirements**
   - THE LocationProvider SHALL implement sortLibrariesByDistance() returning List<LibraryModel>
   - THE LocationProvider SHALL create copy of input list using List<LibraryModel>.from() to avoid mutation
   - THE LocationProvider SHALL call updateLibraryDistances() before sorting to ensure current distances
   - THE LocationProvider SHALL sort libraries with null distanceFromUser to end of list
   - THE LocationProvider SHALL use compareTo() method for numeric distance sorting (ascending order)
   - WHEN user location is null, THE LocationProvider SHALL sort alphabetically by library name

4. **Real-time Updates Requirements**
   - THE LocationProvider SHALL call notifyListeners() after location updates
   - THE LocationProvider SHALL update library distances automatically when _userLocation changes
   - THE Library list UI SHALL rebuild automatically when LocationProvider notifies changes
   - THE LocationProvider SHALL provide updateLibraryDistances() method for manual refresh
   - THE LocationProvider SHALL handle location changes smoothly without UI flickering

5. **Location State Management**
   - THE LocationProvider SHALL maintain _userLocation as Position? field
   - THE LocationProvider SHALL maintain _hasLocationPermission as bool field  
   - THE LocationProvider SHALL maintain _isLoadingLocation as bool field
   - THE LocationProvider SHALL maintain _error as String? field for error messages
   - THE LocationProvider SHALL provide getter methods for all state fields
   - THE LocationProvider SHALL clear error state when clearError() is called

6. **Fallback Behavior Requirements**
   - WHEN location permission is denied, THE Library_Discovery SHALL sort libraries alphabetically by name
   - WHEN GPS is unavailable, THE Library_Discovery SHALL show libraries without distance indicators
   - WHEN location services are disabled, THE Library_Discovery SHALL display explanatory message
   - THE LocationProvider SHALL set _error message explaining fallback behavior to users
   - THE Library list UI SHALL show appropriate icons/indicators for different states

### Requirement 4: Location Permission Management with Clear User Communication

**User Story:** As a reader, I want clear explanations when location permissions are requested and helpful guidance when permissions are denied, so that I understand why the app needs my location and what to do if I change my mind.

#### Acceptance Criteria

1. **Permission Request Flow**
   - THE LocationProvider SHALL call requestLocation() method to initiate permission flow
   - THE LocationProvider SHALL set _isLoadingLocation to true before starting permission request
   - THE LocationProvider SHALL use Permission.location.request() from permission_handler package
   - THE LocationProvider SHALL check for PermissionStatus.granted for success
   - THE LocationProvider SHALL set _hasLocationPermission based on permission result

2. **Permission Status Handling**
   - THE LocationProvider SHALL handle PermissionStatus.denied with retry capability
   - THE LocationProvider SHALL handle PermissionStatus.permanentlyDenied with settings guidance
   - THE LocationProvider SHALL handle PermissionStatus.restricted on iOS appropriately
   - THE LocationProvider SHALL never create permission request loops or spam users
   - THE LocationProvider SHALL store permission status in _hasLocationPermission field

3. **User Communication Requirements**
   - WHEN permission is denied, THE LocationProvider SHALL set _error to "Location permission denied. Libraries will be sorted alphabetically."
   - WHEN GPS is disabled, THE LocationProvider SHALL set _error to "Unable to get your location. Please check GPS settings."
   - WHEN location fails, THE LocationProvider SHALL set _error to "Error getting location: ${e.toString()}"
   - THE LocationProvider SHALL provide clearError() method to dismiss error messages
   - THE UI SHALL display error messages in user-friendly format with appropriate icons

4. **Graceful Degradation**
   - WHEN permission is denied, THE Library_Discovery SHALL continue working with alphabetical sorting
   - WHEN permission is denied, THE Cross_Library_Search SHALL work without distance sorting
   - WHEN permission is denied, THE Maps_Integration SHALL still function for navigation
   - THE LocationProvider SHALL never block app functionality due to permission issues
   - THE UI SHALL clearly indicate when location features are unavailable

5. **Platform Compatibility**
   - THE Permission_Handler SHALL work identically on Android and iOS
   - THE Permission_Handler SHALL handle Android's location permission model correctly
   - THE Permission_Handler SHALL handle iOS's location permission model correctly
   - THE Permission_Handler SHALL handle platform-specific permission states appropriately
   - THE LocationProvider SHALL provide consistent behavior across platforms

6. **Error Recovery**
   - THE LocationProvider SHALL allow users to retry permission request after denial
   - THE LocationProvider SHALL detect when permissions are granted in device settings
   - THE LocationProvider SHALL provide manual refresh capability for location
   - THE LocationProvider SHALL handle app resume scenarios where permissions may have changed
   - THE UI SHALL provide clear actions for users to resolve permission issues

### Requirement 5: Maps Integration and Navigation

**User Story:** As a reader, I want to open my device's maps app to navigate to a library with a single tap, so that I can get turn-by-turn directions easily.

#### Acceptance Criteria

1. **Maps Button Integration**
   - THE Library detail UI SHALL display "Locate Library" button next to Join/Leave library options
   - THE Maps button SHALL use recognizable map icon (Icons.map or Icons.directions)
   - THE Maps button SHALL be styled consistently with other action buttons
   - THE Maps button SHALL be disabled/hidden when library has no coordinates
   - THE Maps button SHALL show loading state during maps app launch

2. **URL Launcher Implementation**
   - THE Maps_Integration SHALL use url_launcher package for opening maps
   - THE Maps_Integration SHALL construct proper maps URLs for both platforms
   - THE Maps_Integration SHALL use "geo:" scheme for Android: "geo:${lat},${lon}?q=${lat},${lon}(${libraryName})"
   - THE Maps_Integration SHALL use "maps:" scheme for iOS: "maps:?q=${lat},${lon}&ll=${lat},${lon}"
   - THE Maps_Integration SHALL URL-encode library name and address for proper handling

3. **Platform-Specific Handling**
   - THE Maps_Integration SHALL detect platform using Platform.isAndroid/Platform.isIOS
   - THE Maps_Integration SHALL use Google Maps format for Android devices
   - THE Maps_Integration SHALL use Apple Maps format for iOS devices
   - THE Maps_Integration SHALL handle web platform gracefully (fallback to Google Maps web)
   - THE Maps_Integration SHALL test URL schemes on both platforms

4. **Error Handling Requirements**
   - THE Maps_Integration SHALL use canLaunchUrl() to check if maps app is available
   - WHEN no maps app is installed, THE Maps_Integration SHALL show error dialog with alternatives
   - WHEN URL launch fails, THE Maps_Integration SHALL display "Unable to open maps app" message
   - THE Maps_Integration SHALL provide fallback option to copy coordinates to clipboard
   - THE Maps_Integration SHALL handle network connectivity issues gracefully

5. **Data Requirements**
   - THE Maps_Integration SHALL require library.latitude and library.longitude to be non-null
   - THE Maps_Integration SHALL use library.name for map pin labeling
   - THE Maps_Integration SHALL use library.formattedAddress for additional context
   - THE Maps_Integration SHALL validate coordinates are within valid ranges (-90 to 90 lat, -180 to 180 lon)
   - THE Maps_Integration SHALL handle missing or invalid coordinate data gracefully

6. **User Experience Requirements**
   - THE Maps button SHALL provide immediate feedback when tapped (loading state)
   - THE Maps_Integration SHALL launch maps app within 2 seconds of button tap
   - THE Maps_Integration SHALL return user to library app when maps app is closed
   - THE Maps button SHALL be easily discoverable and accessible
   - THE Maps_Integration SHALL work offline if maps app supports offline maps

### Requirement 6: Cross-Library Book Search with Distance Sorting

**User Story:** As a reader, I want to search for books across all libraries and see results sorted by distance, so that I can find books at the nearest available library.

#### Acceptance Criteria

1. **Search Integration Requirements**
   - THE Cross_Library_Search SHALL integrate with existing Browse section search functionality
   - THE Cross_Library_Search SHALL search across all libraries in Firestore using collection group queries
   - THE Cross_Library_Search SHALL maintain existing search filters (title, author, ISBN) while adding location sorting
   - THE Cross_Library_Search SHALL preserve existing search UI while adding distance indicators
   - THE Cross_Library_Search SHALL not break existing single-library search functionality

2. **Search Result Format Requirements**
   - THE Cross_Library_Search SHALL display results in format: "Book Title by Author - Available at Library Name (X.X km away)"
   - THE Cross_Library_Search SHALL show book availability status (Available/Borrowed/Reserved) for each library
   - THE Cross_Library_Search SHALL use consistent formatting with existing book list items
   - THE Cross_Library_Search SHALL include book cover images when available
   - THE Cross_Library_Search SHALL show library name prominently for each result

3. **Distance-Based Sorting Requirements**
   - THE Cross_Library_Search SHALL sort results by library distance (nearest first) when user location is available
   - THE Cross_Library_Search SHALL calculate distance using LocationProvider.updateLibraryDistances()
   - THE Cross_Library_Search SHALL group results by book, then sort libraries by distance within each book group
   - THE Cross_Library_Search SHALL fall back to alphabetical library sorting when location is unavailable
   - THE Cross_Library_Search SHALL update sorting when user location changes

4. **Multiple Library Handling**
   - WHEN multiple libraries have the same book, THE Cross_Library_Search SHALL list all libraries with distances
   - THE Cross_Library_Search SHALL show "Available at 3 libraries" summary with expandable details
   - THE Cross_Library_Search SHALL allow users to select which library to visit for each book
   - THE Cross_Library_Search SHALL prioritize libraries with available copies over borrowed copies
   - THE Cross_Library_Search SHALL handle duplicate books across libraries efficiently

5. **Navigation Integration**
   - WHEN a book result is tapped, THE Cross_Library_Search SHALL navigate to that library's detail page
   - THE Cross_Library_Search SHALL pass library ID for proper navigation
   - THE Cross_Library_Search SHALL maintain search context when returning from library page
   - THE Cross_Library_Search SHALL provide "Join Library" option if user is not a member
   - THE Cross_Library_Search SHALL show book details within library context

6. **Performance Requirements**
   - THE Cross_Library_Search SHALL implement efficient Firestore queries to minimize reads
   - THE Cross_Library_Search SHALL use pagination for large result sets (25 results per page)
   - THE Cross_Library_Search SHALL cache search results for 5 minutes to improve performance
   - THE Cross_Library_Search SHALL show loading indicators during search operations
   - THE Cross_Library_Search SHALL handle large datasets (1000+ books across 100+ libraries) efficiently

7. **Fallback Behavior**
   - WHEN user location is unavailable, THE Cross_Library_Search SHALL sort results alphabetically by library name
   - WHEN location permission is denied, THE Cross_Library_Search SHALL show results without distance indicators
   - WHEN no books are found, THE Cross_Library_Search SHALL show appropriate empty state message
   - THE Cross_Library_Search SHALL work fully without location services enabled
   - THE Cross_Library_Search SHALL provide clear feedback about sorting method being used

### Requirement 7: Data Model Extensions and Firestore Integration

**User Story:** As a developer, I want proper data models and Firestore integration to support location features efficiently and reliably, so that location data is stored, retrieved, and validated correctly.

#### Acceptance Criteria

1. **LibraryModel Location Fields**
   - THE LibraryModel SHALL include latitude field as double? (nullable for backward compatibility)
   - THE LibraryModel SHALL include longitude field as double? (nullable for backward compatibility)
   - THE LibraryModel SHALL include formattedAddress field as String? (nullable for backward compatibility)
   - THE LibraryModel SHALL include distanceFromUser field as double? (runtime-only, not stored in Firestore)
   - THE LibraryModel SHALL validate latitude range: -90.0 to 90.0 degrees
   - THE LibraryModel SHALL validate longitude range: -180.0 to 180.0 degrees

2. **Firestore Serialization Requirements**
   - THE LibraryModel.toJson() SHALL include latitude field with null check: if (latitude != null) 'latitude': latitude
   - THE LibraryModel.toJson() SHALL include longitude field with null check: if (longitude != null) 'longitude': longitude
   - THE LibraryModel.toJson() SHALL include formattedAddress field with null check: if (formattedAddress != null) 'formattedAddress': formattedAddress
   - THE LibraryModel.toJson() SHALL NOT include distanceFromUser field (runtime-only)
   - THE LibraryModel.fromJson() SHALL parse latitude as (json['latitude'] as num?)?.toDouble()
   - THE LibraryModel.fromJson() SHALL parse longitude as (json['longitude'] as num?)?.toDouble()
   - THE LibraryModel.fromJson() SHALL parse formattedAddress as json['formattedAddress'] as String?

3. **Data Validation Requirements**
   - THE LibraryModel SHALL validate coordinate pairs: both latitude and longitude must be non-null together
   - THE LibraryModel SHALL reject coordinates where latitude is null but longitude is not null
   - THE LibraryModel SHALL reject coordinates where longitude is null but latitude is not null
   - THE LibraryModel SHALL allow both coordinates to be null (for libraries without location data)
   - THE LibraryModel SHALL validate formattedAddress is not empty string when provided

4. **CopyWith Method Requirements**
   - THE LibraryModel.copyWith() SHALL include latitude parameter as double?
   - THE LibraryModel.copyWith() SHALL include longitude parameter as double?
   - THE LibraryModel.copyWith() SHALL include formattedAddress parameter as String?
   - THE LibraryModel.copyWith() SHALL include distanceFromUser parameter as double?
   - THE LibraryModel.copyWith() SHALL maintain immutability by creating new instances

5. **Firestore Indexing Requirements**
   - THE Firestore libraries collection SHALL create composite index on (latitude, longitude) for location queries
   - THE Firestore SHALL support efficient queries for libraries within geographic bounds
   - THE LibraryModel SHALL store coordinates with sufficient precision (6 decimal places minimum)
   - THE Firestore rules SHALL allow read access to location fields for all authenticated users
   - THE Firestore rules SHALL restrict write access to location fields to library admins only

6. **Backward Compatibility Requirements**
   - THE LibraryModel SHALL handle existing libraries without location data gracefully
   - THE LibraryModel SHALL not break when location fields are missing from Firestore documents
   - THE LibraryModel SHALL provide default null values for missing location fields
   - THE Location features SHALL work when some libraries have location data and others don't
   - THE UI SHALL handle mixed scenarios (some libraries with/without location) appropriately

### Requirement 8: Performance Optimization and Caching Strategy

**User Story:** As a user, I want location-based features to work smoothly and responsively without delays or excessive battery usage, so that I have a seamless experience.

#### Acceptance Criteria

1. **Location Caching Strategy**
   - THE LocationService SHALL cache user location for exactly 5 minutes using _cacheTimeout = Duration(minutes: 5)
   - THE LocationService SHALL store _cachedLocation as Position? and _cacheTime as DateTime?
   - THE LocationService SHALL check cache validity before GPS requests using DateTime.now().difference(_cacheTime!)
   - THE LocationService SHALL return cached location immediately when valid, avoiding GPS activation
   - THE LocationService SHALL provide getCachedLocation() method for synchronous access

2. **Distance Calculation Caching**
   - THE LocationProvider SHALL cache calculated distances in LibraryModel.distanceFromUser field
   - THE LocationProvider SHALL avoid recalculating distances for unchanged user/library positions
   - THE LocationProvider SHALL update distances only when user location changes significantly (>100m)
   - THE Distance calculations SHALL use efficient Geolocator.distanceBetween() method
   - THE LocationProvider SHALL batch distance calculations for multiple libraries efficiently

3. **Geocoding Cache Management**
   - THE GeocodingService SHALL implement permanent caching using Map<String, LocationResult>
   - THE GeocodingService SHALL use lowercase trimmed address as cache key for maximum hit rate
   - THE GeocodingService SHALL never make duplicate API calls for previously geocoded addresses
   - THE GeocodingService SHALL persist cache across app sessions (future enhancement)
   - THE GeocodingService SHALL provide clearCache() method for testing and memory management

4. **UI Performance Requirements**
   - THE Library list SHALL update smoothly with animations when distance sorting changes
   - THE LocationProvider SHALL use notifyListeners() efficiently to minimize unnecessary rebuilds
   - THE Distance indicators SHALL appear without causing UI lag or stuttering
   - THE Location loading states SHALL provide immediate feedback within 100ms
   - THE Library sorting SHALL complete within 500ms for up to 100 libraries

5. **Battery Optimization**
   - THE LocationService SHALL use LocationAccuracy.medium to balance accuracy and battery usage
   - THE LocationService SHALL set timeLimit: Duration(seconds: 10) to prevent GPS hanging
   - THE LocationService SHALL avoid continuous location tracking (only on-demand requests)
   - THE LocationService SHALL cache location to minimize GPS activations
   - THE Permission requests SHALL not repeatedly prompt users (implement request throttling)

6. **Memory Management**
   - THE LocationProvider SHALL extend BaseProvider for proper subscription management
   - THE LocationProvider SHALL cancel location subscriptions in dispose() method
   - THE GeocodingService SHALL implement cache size limits to prevent memory leaks
   - THE LocationService SHALL clear cached data when clearCache() is called
   - THE Distance calculations SHALL not retain references to large objects

### Requirement 9: Comprehensive Error Handling and Fallback Mechanisms

**User Story:** As a user, I want the app to work gracefully when location services fail or are unavailable, so that I can still use all app features effectively with clear understanding of any limitations.

#### Acceptance Criteria

1. **Location Permission Error Handling**
   - WHEN permission is denied, THE LocationProvider SHALL set _error to "Location permission denied. Libraries will be sorted alphabetically."
   - WHEN permission is permanently denied, THE LocationProvider SHALL set _error to "Location access permanently denied. Enable in device settings to see nearby libraries."
   - WHEN permission request fails, THE LocationProvider SHALL set _error to "Unable to request location permission: ${error details}"
   - THE LocationProvider SHALL provide clearError() method to dismiss error messages
   - THE UI SHALL display error messages with appropriate icons and action buttons

2. **GPS and Location Service Errors**
   - WHEN GPS is disabled, THE LocationProvider SHALL set _error to "Unable to get your location. Please check GPS settings."
   - WHEN location services are disabled, THE LocationProvider SHALL set _error to "Location services are disabled. Enable in device settings."
   - WHEN GPS timeout occurs, THE LocationProvider SHALL set _error to "Location request timed out. Please try again."
   - WHEN location accuracy is poor, THE LocationProvider SHALL continue with available data and log warning
   - THE LocationService SHALL handle all Geolocator exceptions gracefully without crashing

3. **Network and API Error Handling**
   - WHEN geocoding API fails, THE GeocodingService SHALL return LocationResult with success: false and descriptive error
   - WHEN network is unavailable, THE GeocodingService SHALL use cached data when available
   - WHEN API quota is exceeded, THE GeocodingService SHALL return cached results with warning message
   - WHEN geocoding returns empty results, THE GeocodingService SHALL return "Address not found" error
   - THE GeocodingService SHALL handle all network exceptions with user-friendly error messages

4. **Maps Integration Error Handling**
   - WHEN no maps app is installed, THE Maps_Integration SHALL show dialog: "No maps app found. Please install Google Maps or Apple Maps."
   - WHEN URL launch fails, THE Maps_Integration SHALL show error: "Unable to open maps app. Please try again."
   - WHEN coordinates are invalid, THE Maps_Integration SHALL show error: "Invalid library location data."
   - THE Maps_Integration SHALL provide fallback option to copy coordinates to clipboard
   - THE Maps_Integration SHALL handle platform-specific URL scheme failures gracefully

5. **Data Validation Error Handling**
   - WHEN library coordinates are null, THE Distance calculations SHALL skip that library gracefully
   - WHEN coordinates are out of valid range, THE LibraryModel SHALL reject the data with validation error
   - WHEN address geocoding fails, THE AddressInputWidget SHALL show specific error and prevent saving
   - WHEN Firestore data is corrupted, THE LibraryModel SHALL use default values and log warning
   - THE Data validation SHALL never cause app crashes or undefined behavior

6. **Fallback Behavior Requirements**
   - WHEN location is unavailable, THE Library_Discovery SHALL sort alphabetically by library name
   - WHEN distance calculation fails, THE Library list SHALL show libraries without distance indicators
   - WHEN geocoding fails, THE Address input SHALL allow manual coordinate entry (future enhancement)
   - WHEN maps integration fails, THE UI SHALL provide alternative contact information
   - THE App SHALL remain fully functional even when all location services are disabled

7. **Error Recovery Mechanisms**
   - THE LocationProvider SHALL allow users to retry location requests after failures
   - THE LocationProvider SHALL detect when permissions are granted and automatically retry
   - THE GeocodingService SHALL retry failed requests with exponential backoff
   - THE UI SHALL provide clear actions for users to resolve permission and settings issues
   - THE Error states SHALL be recoverable without requiring app restart

### Requirement 10: Professional User Interface and User Experience

**User Story:** As a user, I want a professional, intuitive, and polished interface for location features that feels consistent with commercial apps, so that the app provides a premium user experience.

#### Acceptance Criteria

1. **Address Input Interface Design**
   - THE AddressInputWidget SHALL use Material Design 3 styling with OutlineInputBorder
   - THE AddressInputWidget SHALL include location_on prefixIcon in primary color
   - THE AddressInputWidget SHALL show loading spinner (CircularProgressIndicator) during validation
   - THE AddressInputWidget SHALL display green check_circle icon when address is valid
   - THE AddressInputWidget SHALL use 2 maxLines for address input to accommodate long addresses
   - THE AddressInputWidget SHALL include helpful info container with blue background explaining format requirements

2. **Distance Display Design**
   - THE Library list SHALL display distance in consistent format: "2.5km away" or "250m away"
   - THE Distance indicators SHALL use subtle gray text color to not overwhelm library names
   - THE Distance text SHALL be positioned consistently (right-aligned or below library name)
   - THE Library cards SHALL include location pin icons for libraries with location data
   - THE Distance loading SHALL show skeleton placeholders during calculation

3. **Maps Integration Button Design**
   - THE "Locate Library" button SHALL use recognizable map icon (Icons.map or Icons.directions)
   - THE Maps button SHALL be styled consistently with other action buttons (Join/Leave)
   - THE Maps button SHALL use primary color scheme matching app theme
   - THE Maps button SHALL show loading state during maps app launch
   - THE Maps button SHALL be disabled with gray styling when library has no location data

4. **Loading States and Feedback**
   - THE Location requests SHALL show loading indicators within 100ms of user action
   - THE Address validation SHALL display loading spinner in input field suffix
   - THE Library list SHALL show skeleton loading for distance calculations
   - THE Maps button SHALL show loading state during URL launch
   - THE Loading indicators SHALL use consistent styling across all location features

5. **Error State Design**
   - THE Error messages SHALL use consistent red color scheme (AppColors.error)
   - THE Error states SHALL include appropriate icons (warning, error, info)
   - THE Error messages SHALL be displayed in user-friendly language without technical jargon
   - THE Error states SHALL provide clear action buttons for resolution
   - THE Error containers SHALL use consistent padding and border radius

6. **Responsive Design Requirements**
   - THE Location features SHALL work properly on different screen sizes (phones, tablets)
   - THE Address input SHALL adapt to different keyboard types and input methods
   - THE Library list SHALL maintain proper spacing and alignment with distance indicators
   - THE Maps button SHALL be appropriately sized for touch interaction (minimum 44px)
   - THE UI elements SHALL follow Material Design accessibility guidelines

7. **Animation and Transitions**
   - THE Library list sorting SHALL use smooth animations when distance order changes
   - THE Distance indicators SHALL fade in smoothly when location is acquired
   - THE Loading states SHALL transition smoothly to content or error states
   - THE Button states SHALL provide immediate visual feedback on tap
   - THE Animations SHALL be subtle and not distract from core functionality

8. **Accessibility Requirements**
   - THE Location features SHALL support screen readers with proper semantic labels
   - THE Maps button SHALL have descriptive accessibility label: "Navigate to [Library Name]"
   - THE Distance indicators SHALL be announced by screen readers
   - THE Error messages SHALL be properly announced to assistive technologies
   - THE Loading states SHALL provide appropriate accessibility feedback

### Requirement 11: Cross-Platform Compatibility and Platform-Specific Optimizations

**User Story:** As a user on any mobile platform, I want location features to work consistently and optimally, so that I have the same high-quality experience regardless of my device type.

#### Acceptance Criteria

1. **Android Platform Requirements**
   - THE LocationService SHALL handle Android's runtime permission model correctly
   - THE LocationService SHALL work with Android 6.0+ (API 23+) permission system
   - THE Maps_Integration SHALL use "geo:" URL scheme for Android: "geo:${lat},${lon}?q=${lat},${lon}(${libraryName})"
   - THE LocationService SHALL handle Android location provider variations (GPS, Network, Fused)
   - THE Permission_Handler SHALL handle Android's "Don't ask again" permission state

2. **iOS Platform Requirements**
   - THE LocationService SHALL handle iOS location permission model (When In Use vs Always)
   - THE LocationService SHALL request "When In Use" permission for library discovery features
   - THE Maps_Integration SHALL use "maps:" URL scheme for iOS: "maps:?q=${lat},${lon}&ll=${lat},${lon}"
   - THE LocationService SHALL handle iOS location accuracy authorization levels
   - THE Permission_Handler SHALL handle iOS permission states correctly

3. **Platform Detection and Handling**
   - THE Maps_Integration SHALL use Platform.isAndroid and Platform.isIOS for platform detection
   - THE Maps_Integration SHALL import 'dart:io' for Platform class access
   - THE URL schemes SHALL be constructed differently for each platform
   - THE Error messages SHALL be platform-appropriate for permission guidance
   - THE LocationService SHALL handle platform-specific location accuracy differences

4. **Package Compatibility**
   - THE geolocator package SHALL work identically on both Android and iOS
   - THE geocoding package SHALL provide consistent results across platforms
   - THE permission_handler package SHALL handle platform-specific permission models
   - THE url_launcher package SHALL work with platform-specific URL schemes
   - THE Package versions SHALL be compatible with both platforms

5. **Testing Requirements**
   - THE Location features SHALL be tested on both Android and iOS devices
   - THE Permission flows SHALL be tested on both platforms with different permission states
   - THE Maps integration SHALL be tested with different maps apps on each platform
   - THE Distance calculations SHALL produce identical results on both platforms
   - THE UI layouts SHALL be verified on different screen sizes for both platforms

6. **Platform-Specific Optimizations**
   - THE Android implementation SHALL use Fused Location Provider when available
   - THE iOS implementation SHALL respect battery optimization settings
   - THE Permission requests SHALL use platform-appropriate timing and context
   - THE Error handling SHALL provide platform-specific guidance for settings
   - THE Performance SHALL be optimized for each platform's characteristics

### Requirement 12: Security, Privacy, and Data Protection

**User Story:** As a user, I want my location data to be handled securely and privately, so that I can trust the app with my sensitive location information.

#### Acceptance Criteria

1. **Location Data Privacy**
   - THE LocationService SHALL only request location when explicitly needed for features
   - THE LocationService SHALL NOT track or store user location permanently
   - THE LocationService SHALL cache location for maximum 5 minutes only
   - THE LocationService SHALL clear cached location when app is backgrounded
   - THE User location SHALL never be transmitted to external services except for geocoding

2. **Permission Transparency**
   - THE Permission requests SHALL clearly explain why location is needed
   - THE Permission requests SHALL specify that location is used only for finding nearby libraries
   - THE Permission requests SHALL never request more permissions than necessary
   - THE App SHALL function fully when location permission is denied
   - THE Privacy policy SHALL clearly document location data usage

3. **Data Minimization**
   - THE GeocodingService SHALL only send addresses to Google Geocoding API, never user location
   - THE LocationService SHALL use minimum required location accuracy (medium, not high)
   - THE Distance calculations SHALL be performed locally, not on external servers
   - THE Library coordinates SHALL be stored with appropriate precision (6 decimal places maximum)
   - THE App SHALL not collect location analytics or tracking data

4. **Secure Data Transmission**
   - THE Geocoding API calls SHALL use HTTPS encryption
   - THE Library location data SHALL be transmitted securely to/from Firestore
   - THE Maps URLs SHALL not expose sensitive user information
   - THE Error messages SHALL not leak sensitive system information
   - THE Network requests SHALL implement proper certificate validation

5. **Data Retention and Cleanup**
   - THE LocationService SHALL automatically clear cached location after timeout
   - THE GeocodingService cache SHALL be cleared when app is uninstalled
   - THE User location SHALL not be persisted to device storage
   - THE Library coordinates SHALL only be stored for legitimate business purposes
   - THE App SHALL provide clear data deletion mechanisms

6. **Firestore Security Rules**
   - THE Library location fields SHALL be readable by all authenticated users
   - THE Library location fields SHALL be writable only by library admins (adminUid match)
   - THE Location data SHALL not be accessible to unauthenticated users
   - THE Firestore rules SHALL prevent unauthorized location data modification
   - THE Security rules SHALL be tested for proper access control

## Implementation Guidelines and Common Pitfalls

### Critical Implementation Notes

**AVOID THESE COMMON MISTAKES:**

1. **Location Permission Loops**: Never repeatedly request permissions. Check current status before requesting.
2. **GPS Hanging**: Always set timeLimit: Duration(seconds: 10) for getCurrentPosition() calls.
3. **Cache Key Inconsistency**: Always use lowercase trimmed strings as cache keys for geocoding.
4. **Null Safety Violations**: Always check latitude != null && longitude != null together.
5. **Platform URL Schemes**: Use correct URL schemes: "geo:" for Android, "maps:" for iOS.
6. **Firestore Field Names**: Use exact field names: 'latitude', 'longitude', 'formattedAddress'.
7. **Distance Unit Confusion**: Geolocator.distanceBetween() returns meters, divide by 1000 for kilometers.
8. **State Management**: Always call notifyListeners() after updating LocationProvider state.
9. **Memory Leaks**: Extend BaseProvider and properly dispose subscriptions.
10. **Error Swallowing**: Never catch exceptions without providing user feedback.

### Required Package Versions

```yaml
dependencies:
  geolocator: ^10.1.0
  geocoding: ^2.1.1
  permission_handler: ^11.0.1
  url_launcher: ^6.2.1
```

### Firestore Security Rules

```javascript
// Add to firestore.rules
match /libraries/{libraryId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && 
    request.auth.uid == resource.data.adminUid;
  
  // Location fields can be read by all authenticated users
  // but only written by library admin
  allow update: if request.auth != null && 
    request.auth.uid == resource.data.adminUid &&
    validateLocationFields();
}

function validateLocationFields() {
  return (
    // Latitude must be between -90 and 90
    (!('latitude' in request.resource.data) || 
     (request.resource.data.latitude >= -90.0 && 
      request.resource.data.latitude <= 90.0)) &&
    
    // Longitude must be between -180 and 180
    (!('longitude' in request.resource.data) || 
     (request.resource.data.longitude >= -180.0 && 
      request.resource.data.longitude <= 180.0)) &&
    
    // Both coordinates must be present together or both null
    (('latitude' in request.resource.data && 'longitude' in request.resource.data) ||
     (!('latitude' in request.resource.data) && !('longitude' in request.resource.data)))
  );
}
```

### Testing Checklist

**Before marking any requirement as complete, verify:**

- [ ] Location permission request works on both Android and iOS
- [ ] Permission denial doesn't break app functionality
- [ ] GPS timeout doesn't cause app hang
- [ ] Address validation rejects incomplete addresses
- [ ] Geocoding cache prevents duplicate API calls
- [ ] Distance calculations are accurate and consistent
- [ ] Maps integration opens correct app on both platforms
- [ ] Library list sorts correctly by distance
- [ ] Cross-library search includes distance information
- [ ] Error messages are user-friendly and actionable
- [ ] Loading states provide immediate feedback
- [ ] App works offline with cached data
- [ ] Memory usage is reasonable (no leaks)
- [ ] Battery usage is optimized (no continuous tracking)
- [ ] UI is responsive and professional-looking

### Performance Benchmarks

**The implementation must meet these performance requirements:**

- Location acquisition: < 10 seconds
- Distance calculation for 100 libraries: < 500ms
- Library list sorting: < 200ms
- Address validation: < 2 seconds
- Maps app launch: < 2 seconds
- UI state updates: < 100ms
- Memory usage: < 50MB additional for location features
- Battery impact: < 5% additional drain per hour of usage

### Error Message Standards

**Use these exact error messages for consistency:**

- Permission denied: "Location permission denied. Libraries will be sorted alphabetically."
- GPS disabled: "Unable to get your location. Please check GPS settings."
- Network error: "Network error. Using cached location data."
- Geocoding failed: "Address not found. Please check the address format."
- Maps unavailable: "No maps app found. Please install Google Maps or Apple Maps."
- Invalid coordinates: "Invalid library location data."
- Timeout: "Location request timed out. Please try again."

## Acceptance Testing Scenarios

### Scenario 1: Library Admin Sets Address

**Given:** Library admin is logged in and on library settings page
**When:** Admin enters complete address "123 Main St, Springfield, IL, USA"
**Then:** 
- Address validates successfully with green checkmark
- Geocoding converts to coordinates (39.7817, -89.6501)
- Address saves to Firestore with all three fields
- Success message appears: "Address saved successfully!"

### Scenario 2: Reader Views Nearby Libraries

**Given:** Reader has granted location permission and is at coordinates (40.7128, -74.0060)
**When:** Reader opens library discovery page
**Then:**
- App requests current location (cached if recent)
- Libraries sort by distance with nearest first
- Distance displays as "2.5km away" or "250m away"
- Libraries without coordinates appear at end alphabetically

### Scenario 3: Reader Navigates to Library

**Given:** Reader is viewing library with coordinates (40.7589, -73.9851)
**When:** Reader taps "Locate Library" button
**Then:**
- Maps app opens with library location marked
- Library name appears as map pin label
- User can get turn-by-turn directions
- Returning to app maintains previous state

### Scenario 4: Cross-Library Book Search

**Given:** Reader searches for "Harry Potter" across all libraries
**When:** Search results load
**Then:**
- Results show "Harry Potter - Available at Central Library (1.2km away)"
- Multiple libraries listed for same book, sorted by distance
- Tapping result navigates to that library's page
- Search works without location (alphabetical sorting)

### Scenario 5: Permission Denied Graceful Fallback

**Given:** Reader denies location permission
**When:** Reader uses location-dependent features
**Then:**
- Libraries sort alphabetically by name
- No distance indicators shown
- Clear message explains limitation
- All other features work normally
- No permission request loops occur

This comprehensive requirements document provides the detailed specifications needed to implement location-based features without common mistakes or stubborn errors. Every technical detail, error condition, and edge case has been specified to ensure successful implementation.