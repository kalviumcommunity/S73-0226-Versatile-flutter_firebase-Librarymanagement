# Implementation Plan: Modern UI Redesign

## Overview

This implementation plan breaks down the comprehensive UI redesign into 8 phases over an 8-week period. The redesign focuses exclusively on visual presentation and user interface components while preserving all existing functionality, business logic, API calls, and routing.

The approach follows a token-based design system architecture with reusable components, ensuring consistency across all screens. Each phase includes implementation tasks and testing tasks to validate correctness properties and functionality preservation.

## Implementation Approach

- **Incremental Migration**: Migrate screens one at a time, testing thoroughly before moving forward
- **Functionality Preservation**: Never modify business logic, providers, repositories, or services
- **Testing First**: Write tests alongside implementation to catch regressions early
- **Design Tokens**: Use centralized constants for all styling to ensure consistency

## Tasks

### Phase 1: Design System Foundation (Week 1)

- [x] 1. Update design token constants
  - [x] 1.1 Update color palette in `lib/core/constants/app_colors.dart`
    - Add primary colors (primary, primaryLight, primaryDark, accent)
    - Add background & surface colors (background, surface, surfaceVariant)
    - Add text colors (textPrimary, textSecondary, textTertiary)
    - Add status colors (success, warning, error, info)
    - Add border & divider colors
    - Add badge colors for all status types
    - _Requirements: 1.1, 1.6_

  - [x] 1.2 Update spacing and sizing tokens in `lib/core/constants/app_dimens.dart`
    - Add spacing system (xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48)
    - Add border radius values (sm: 8, md: 12, lg: 16, xl: 24, round: 100)
    - Add elevation values (none: 0, sm: 1, md: 2, lg: 4)
    - Add icon sizes (sm: 18, md: 24, lg: 32, xl: 48)
    - Add component dimensions (minTouchTarget: 48, buttonHeight: 52, inputHeight: 52, cardPadding: 16)
    - _Requirements: 1.3, 1.4, 1.5, 1.8, 16.1, 16.2_


- [x] 2. Configure comprehensive theme in `lib/core/theme/app_theme.dart`
  - [x] 2.1 Define typography system with TextTheme
    - Configure headlineLarge (28px, w700) for page titles
    - Configure headlineMedium (24px, w700) for section titles
    - Configure headlineSmall (20px, w600) for card titles
    - Configure titleLarge (18px, w600) for subtitles
    - Configure bodyLarge (16px, w400) for primary content
    - Configure bodyMedium (14px, w400) for secondary content
    - Configure bodySmall (12px, w400) for captions
    - Use Inter font family with Roboto fallback
    - _Requirements: 1.2, 1.7_

  - [x] 2.2 Configure Material component themes
    - Configure ColorScheme with all semantic colors
    - Configure CardTheme (elevation, shape, shadowColor)
    - Configure ElevatedButtonTheme (height, radius, colors)
    - Configure TextButtonTheme (colors, padding)
    - Configure OutlinedButtonTheme (border, colors)
    - Configure InputDecorationTheme (filled style, borders, focus states)
    - Configure AppBarTheme (elevation, colors, title style)
    - Configure BottomNavigationBarTheme (colors, elevation)
    - _Requirements: 22.3, 22.4, 22.5, 22.6, 22.7, 22.8_

  - [x] 2.3 Apply theme globally in `lib/main.dart`
    - Set theme in MaterialApp
    - Verify theme applies to all screens
    - _Requirements: 22.9_

- [x] 3. Checkpoint - Verify theme application
  - Visually inspect all existing screens with new theme
  - Verify no layout breaks or functionality regressions
  - Test navigation flows work identically
  - Ensure all existing features function correctly
  - _Requirements: 21.1-21.10_


### Phase 2: Component Library Development (Week 2)

- [x] 4. Create card component library
  - [x] 4.1 Create directory structure `lib/core/widgets/cards/`
    - Create cards directory
    - _Requirements: 23.2_

  - [x] 4.2 Implement LibraryCard widget in `library_card.dart`
    - Display library icon with gradient background (48x48dp)
    - Display library name (headlineSmall style)
    - Display description (bodyMedium, max 2 lines with ellipsis)
    - Display member count with icon
    - Display book count with icon
    - Display distance indicator (conditional, when available)
    - Display join status badge
    - Use AppDimens.radiusMd for border radius
    - Use AppDimens.cardPadding for internal padding
    - Use AppDimens.elevationSm for elevation
    - Add InkWell for tap feedback
    - _Requirements: 3.1, 3.2, 3.3, 3.6, 7.3, 7.4, 7.5, 7.9, 23.7_

  - [ ]* 4.3 Write unit tests for LibraryCard
    - Test with complete library data
    - Test with missing optional fields (distance)
    - Test tap callback invocation
    - Test badge display for different join statuses
    - _Requirements: 3.6, 7.3_

  - [x] 4.4 Implement BookCard widget in `book_card.dart`
    - Display book cover with 3:4 aspect ratio and placeholder
    - Display title (titleMedium, max 2 lines with ellipsis)
    - Display author (bodyMedium, max 1 line with ellipsis)
    - Display library name with icon (bodySmall)
    - Display availability badge
    - Use AppDimens.radiusMd for border radius
    - Use AppDimens.sm for internal padding
    - Use AppDimens.elevationSm for elevation
    - Add InkWell for tap feedback
    - Use CachedNetworkImage with error widget
    - _Requirements: 3.1, 3.2, 3.3, 3.7, 6.2, 6.3, 6.4, 6.5, 6.6, 23.7_

  - [ ]* 4.5 Write unit tests for BookCard
    - Test with complete book data
    - Test with missing cover image (placeholder display)
    - Test tap callback invocation
    - Test text ellipsis for long titles/authors
    - _Requirements: 3.7, 6.2-6.6_

  - [x] 4.6 Implement ReservationCard widget in `reservation_card.dart`
    - Display book cover thumbnail (60x80dp)
    - Display book title and author
    - Display reservation date with icon
    - Display expiry date with icon
    - Display status badge
    - Display action buttons (View QR, Cancel)
    - Use AppDimens.radiusMd for border radius
    - Use AppDimens.cardPadding for internal padding
    - Use AppDimens.elevationSm for elevation
    - _Requirements: 3.1, 3.2, 3.3, 19.1, 19.2, 23.7_

  - [ ]* 4.7 Write unit tests for ReservationCard
    - Test with complete reservation data
    - Test button callback invocations
    - Test status badge display for different states
    - _Requirements: 19.1, 19.2_

  - [x] 4.8 Implement TransactionCard widget in `transaction_card.dart`
    - Display book cover thumbnail (60x80dp)
    - Display book title and author
    - Display borrow date with icon
    - Display due date with icon
    - Display return date (conditional, when returned)
    - Display fee amount (conditional, when applicable)
    - Display status badge
    - Use AppDimens.radiusMd for border radius
    - Use AppDimens.cardPadding for internal padding
    - Use AppDimens.elevationSm for elevation
    - _Requirements: 3.1, 3.2, 3.3, 19.3, 23.7_

  - [ ]* 4.9 Write unit tests for TransactionCard
    - Test with active transaction
    - Test with returned transaction
    - Test with overdue transaction
    - Test conditional fee display
    - _Requirements: 19.3_

  - [x] 4.10 Implement StatCard widget in `stat_card.dart`
    - Display optional icon (iconLg size)
    - Display value (headlineMedium style)
    - Display label (bodyMedium style)
    - Use 1:1 aspect ratio (square)
    - Use AppDimens.radiusMd for border radius
    - Use AppDimens.cardPadding for internal padding
    - Use AppDimens.elevationSm for elevation
    - _Requirements: 3.1, 3.2, 3.3, 8.2, 23.7_

  - [ ]* 4.11 Write unit tests for StatCard
    - Test with icon
    - Test without icon
    - Test with various value formats
    - _Requirements: 8.2_


- [x] 5. Create badge and empty state components
  - [x] 5.1 Create directory structure `lib/core/widgets/badges/`
    - Create badges directory
    - _Requirements: 23.5_

  - [x] 5.2 Implement StatusBadge widget in `status_badge.dart`
    - Support BadgeType enum (available, unavailable, pending, custom)
    - Use rounded pill shape (radiusRound)
    - Use 8px horizontal, 4px vertical padding
    - Use 11px font size with bold weight (w600)
    - Use uppercase text transform
    - Implement color variants for each status type
    - Support custom colors for flexibility
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 23.5_

  - [ ]* 5.3 Write unit tests for StatusBadge
    - Test available badge colors
    - Test unavailable badge colors
    - Test pending badge colors
    - Test custom badge colors
    - _Requirements: 11.1-11.7_

  - [x] 5.4 Create directory structure `lib/core/widgets/empty_states/`
    - Create empty_states directory
    - _Requirements: 23.6_

  - [x] 5.5 Implement EmptyStateWidget in `empty_state_widget.dart`
    - Display icon (64dp size, textTertiary color)
    - Display title (headlineSmall style)
    - Display message (bodyMedium style, centered, max 280dp width)
    - Display optional action button
    - Center content vertically and horizontally
    - Use appropriate spacing (16px between icon and title, 8px between title and message, 24px before button)
    - _Requirements: 10.1, 10.2, 10.3, 23.6, 23.7_

  - [ ]* 5.6 Write unit tests for EmptyStateWidget
    - Test with action button
    - Test without action button
    - Test button callback invocation
    - _Requirements: 10.1, 10.2, 10.3_

- [ ]* 6. Write property-based tests for card components
  - [ ]* 6.1 Write property test for LibraryCard information completeness
    - **Property 2: Library Card Information Completeness**
    - **Validates: Requirements 3.6, 7.3**
    - Generate 100+ random LibraryModel instances
    - Verify all required fields are displayed (name, description, member count, book count, join status)
    - Tag: `// Feature: modern-ui-redesign, Property 2`

  - [ ]* 6.2 Write property test for BookCard information completeness
    - **Property 3: Book Card Information Completeness**
    - **Validates: Requirements 3.7**
    - Generate 100+ random BookModel instances
    - Verify all required fields are displayed (cover/placeholder, title, author, library name, availability badge)
    - Tag: `// Feature: modern-ui-redesign, Property 3`

  - [ ]* 6.3 Write property test for ReservationCard information completeness
    - **Property 8: Reservation Card Information Completeness**
    - **Validates: Requirements 19.1**
    - Generate 100+ random ReservationModel instances
    - Verify all required fields are displayed (book info, status badge, dates)
    - Tag: `// Feature: modern-ui-redesign, Property 8`

  - [ ]* 6.4 Write property test for TransactionCard information completeness
    - **Property 9: Transaction Card Information Completeness**
    - **Validates: Requirements 19.3**
    - Generate 100+ random BorrowTransactionModel instances
    - Verify all required fields are displayed (book info, dates, status badge, fee if applicable)
    - Tag: `// Feature: modern-ui-redesign, Property 9`

- [ ]* 7. Create golden test files for visual regression
  - [ ]* 7.1 Create golden tests for all card components
    - Create golden file for LibraryCard
    - Create golden file for BookCard
    - Create golden file for ReservationCard
    - Create golden file for TransactionCard
    - Create golden file for StatCard
    - _Requirements: 23.2_

  - [ ]* 7.2 Create golden tests for badge and empty state
    - Create golden file for StatusBadge (all variants)
    - Create golden file for EmptyStateWidget
    - _Requirements: 23.5, 23.6_

- [x] 8. Checkpoint - Component library complete
  - Ensure all component tests pass
  - Verify components use design tokens consistently
  - Ask user if questions arise


### Phase 3: Screen Redesign - Discovery & Browsing (Week 3)

- [x] 9. Redesign library discovery screen
  - [x] 9.1 Update `lib/features/library/screens/discover_libraries_screen.dart`
    - Replace existing UI with LibraryCard components
    - Implement search bar with new styling (52dp height, filled style)
    - Add "My Libraries" section with horizontal chip scroll
    - Add "All Libraries" section header
    - Use 20px horizontal padding, 16px vertical spacing
    - Use 12px spacing between cards
    - Implement EmptyStateWidget for no libraries
    - Implement CircularProgressIndicator for loading state
    - Preserve all existing functionality (search, navigation, data loading)
    - _Requirements: 5.1, 5.2, 5.3, 7.1, 7.2, 7.6, 7.7, 7.8, 10.1, 12.1, 14.1, 14.2, 21.3_

  - [ ]* 9.2 Write widget tests for discover libraries screen
    - Test search functionality preservation
    - Test navigation to library detail
    - Test empty state display
    - Test loading state display
    - _Requirements: 7.1-7.8, 10.1, 12.1_

- [x] 10. Redesign book browsing screen
  - [x] 10.1 Update `lib/features/books/screens/browse_books_screen.dart`
    - Replace existing UI with BookCard components
    - Implement 2-column grid layout with 16px spacing
    - Implement search bar with new styling (52dp height, filled style)
    - Add category filter chips below search bar (8px spacing)
    - Use 20px horizontal padding, 16px vertical spacing
    - Implement EmptyStateWidget for no books
    - Implement CircularProgressIndicator for loading state
    - Preserve all existing functionality (search, filtering, navigation, data loading)
    - _Requirements: 5.1, 5.2, 5.3, 6.1, 6.7, 6.8, 6.9, 10.1, 12.1, 14.1, 14.2, 21.4_

  - [ ]* 10.2 Write widget tests for browse books screen
    - Test search functionality preservation
    - Test filter chip functionality
    - Test navigation to book detail
    - Test empty state display
    - Test loading state display
    - _Requirements: 6.1-6.9, 10.1, 12.1_

- [x] 11. Redesign library detail screen
  - [x] 11.1 Update `lib/features/library/screens/library_detail_screen.dart`
    - Update layout with design tokens for spacing
    - Use StatusBadge for membership status
    - Update button styling to match theme
    - Use consistent padding (20px horizontal, 16px vertical)
    - Preserve all existing functionality (join library, view books, navigation)
    - _Requirements: 14.1, 14.2, 21.2_

  - [ ]* 11.2 Write widget tests for library detail screen
    - Test join functionality preservation
    - Test navigation to books
    - Test data display
    - _Requirements: 21.2_

- [x] 12. Redesign book detail screen
  - [x] 12.1 Update `lib/features/books/screens/book_detail_screen.dart`
    - Update layout with design tokens for spacing
    - Use StatusBadge for availability status
    - Update button styling to match theme
    - Use consistent padding (20px horizontal, 16px vertical)
    - Preserve all existing functionality (reserve book, view details, navigation)
    - _Requirements: 11.7, 14.1, 14.2, 21.4_

  - [ ]* 12.2 Write widget tests for book detail screen
    - Test reservation functionality preservation
    - Test data display
    - Test button interactions
    - _Requirements: 21.4_

- [ ]* 13. Write property-based tests for conditional rendering
  - [ ]* 13.1 Write property test for conditional distance display
    - **Property 5: Conditional Distance Display**
    - **Validates: Requirements 7.4**
    - Generate LibraryCard instances with and without distance
    - Verify distance indicator displays only when distance is non-null
    - Tag: `// Feature: modern-ui-redesign, Property 5`

  - [ ]* 13.2 Write property test for empty state display
    - **Property 6: Empty State Display**
    - **Validates: Requirements 10.1**
    - Test list/grid views with empty and non-empty data sources
    - Verify EmptyStateWidget displays only when data is empty
    - Tag: `// Feature: modern-ui-redesign, Property 6`

  - [ ]* 13.3 Write property test for loading state display
    - **Property 7: Loading State Display**
    - **Validates: Requirements 12.1**
    - Test screens with loading true and false states
    - Verify CircularProgressIndicator displays only during loading
    - Tag: `// Feature: modern-ui-redesign, Property 7`

- [ ]* 14. Create golden tests for discovery and browsing screens
  - [ ]* 14.1 Create golden tests for library discovery screen
    - Create golden file for screen with data
    - Create golden file for empty state
    - Create golden file for loading state
    - _Requirements: 7.1-7.8_

  - [ ]* 14.2 Create golden tests for book browsing screen
    - Create golden file for screen with data
    - Create golden file for empty state
    - Create golden file for loading state
    - _Requirements: 6.1-6.9_

- [x] 15. Checkpoint - Discovery and browsing screens complete
  - Ensure all tests pass
  - Verify search and filtering work identically
  - Verify navigation flows work correctly
  - Ask user if questions arise


### Phase 4: Screen Redesign - Dashboards (Week 4)

- [x] 16. Redesign reader dashboard
  - [x] 16.1 Update `lib/features/reader/screens/reader_home_screen.dart` (or equivalent)
    - Implement StatCard components for reader metrics (active borrows, pending reservations)
    - Use 2-column grid layout with 16px spacing
    - Add "Quick Actions" section with action buttons
    - Add "Recent Activity" section with TransactionCard components
    - Use consistent spacing (20px horizontal padding, 16px vertical spacing, 24px section spacing)
    - Implement EmptyStateWidget for no recent activity
    - Preserve all existing functionality (navigation, data loading)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.7, 14.1, 14.2, 14.5, 21.1_

  - [ ]* 16.2 Write widget tests for reader dashboard
    - Test stat card display with various metrics
    - Test quick action navigation
    - Test recent activity display
    - Test empty state for no activity
    - _Requirements: 8.1-8.7_

- [x] 17. Redesign librarian dashboard
  - [x] 17.1 Update `lib/features/librarian/screens/librarian_dashboard_screen.dart` (or equivalent)
    - Implement StatCard components for librarian metrics (book inventory, active borrows, pending reservations)
    - Use 2-column grid layout with 16px spacing
    - Add "Quick Actions" section with action buttons
    - Use consistent spacing (20px horizontal padding, 16px vertical spacing, 24px section spacing)
    - Preserve all existing functionality (navigation, data loading)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.7, 14.1, 14.2, 14.5, 21.1_

  - [ ]* 17.2 Write widget tests for librarian dashboard
    - Test stat card display with various metrics
    - Test quick action navigation
    - _Requirements: 8.1-8.7_

- [x] 18. Redesign admin dashboard (if separate screen exists)
  - [x] 18.1 Update admin dashboard screen
    - Implement StatCard components for admin metrics (library count, user count, transaction metrics)
    - Use 2-column grid layout with 16px spacing
    - Add "Quick Actions" section with action buttons
    - Use consistent spacing (20px horizontal padding, 16px vertical spacing, 24px section spacing)
    - Preserve all existing functionality (navigation, data loading)
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 14.1, 14.2, 14.5, 20.5_

  - [ ]* 18.2 Write widget tests for admin dashboard
    - Test stat card display with various metrics
    - Test quick action navigation
    - _Requirements: 8.1-8.6, 20.5_

- [ ]* 19. Create golden tests for dashboard screens
  - [ ]* 19.1 Create golden tests for reader dashboard
    - Create golden file for dashboard with data
    - Create golden file for empty recent activity
    - _Requirements: 8.1-8.7_

  - [ ]* 19.2 Create golden tests for librarian dashboard
    - Create golden file for dashboard with data
    - _Requirements: 8.1-8.7_

  - [ ]* 19.3 Create golden tests for admin dashboard
    - Create golden file for dashboard with data
    - _Requirements: 8.1-8.6_

- [x] 20. Checkpoint - Dashboard screens complete
  - Ensure all tests pass
  - Verify metrics display correctly
  - Verify navigation from dashboards works
  - Ask user if questions arise


### Phase 5: Screen Redesign - Reservations & Transactions (Week 5)

- [x] 21. Redesign reader reservation screen
  - [x] 21.1 Update `lib/features/reservations/screens/reader_reservation_screen.dart`
    - Replace existing UI with ReservationCard components
    - Use vertical list layout with 12px spacing between cards
    - Use 20px horizontal padding
    - Implement EmptyStateWidget for no reservations
    - Implement CircularProgressIndicator for loading state
    - Update QR dialog styling (rounded corners, elevation, padding)
    - Preserve all existing functionality (view QR, cancel reservation, data loading)
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 10.1, 12.1, 14.1, 14.2, 19.1, 19.2, 19.5, 21.4_

  - [ ]* 21.2 Write widget tests for reader reservation screen
    - Test reservation display
    - Test QR dialog display
    - Test cancel functionality preservation
    - Test empty state display
    - Test loading state display
    - _Requirements: 19.1, 19.2, 19.5_

- [x] 22. Redesign librarian reservation scanner
  - [ ] 22.1 Update `lib/features/reservations/screens/librarian_reservation_scanner.dart`
    - Update QR scanner overlay styling (semi-transparent background, white border)
    - Update scanner cutout (250x250dp centered, 2px white border)
    - Update instructions text styling (24px from scanner)
    - Update close button styling (48x48dp top-left)
    - Preserve all existing functionality (QR scanning, code processing)
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6, 21.4_

  - [ ]* 22.2 Write widget tests for librarian reservation scanner
    - Test scanner UI display
    - Test close button functionality
    - _Requirements: 17.1-17.6_

- [x] 23. Redesign reader transactions screen
  - [x] 23.1 Update `lib/features/borrow/screens/reader_transactions_screen.dart`
    - Replace existing UI with TransactionCard components
    - Implement tab navigation (Active, Overdue, Returned) with 48dp height
    - Use vertical list layout with 12px spacing between cards
    - Use 20px horizontal padding
    - Implement EmptyStateWidget for each tab when no transactions
    - Implement CircularProgressIndicator for loading state
    - Preserve all existing functionality (tab switching, data loading, navigation)
    - _Requirements: 10.1, 12.1, 14.1, 14.2, 19.3, 19.4, 21.5_

  - [ ]* 23.2 Write widget tests for reader transactions screen
    - Test transaction display in each tab
    - Test tab switching functionality
    - Test empty state display for each tab
    - Test loading state display
    - _Requirements: 19.3, 19.4_

- [x] 24. Redesign librarian borrow screen
  - [ ] 24.1 Update `lib/features/borrow/screens/librarian_borrow_screen.dart`
    - Update layout with design tokens for spacing
    - Update button styling to match theme
    - Update input field styling to match theme
    - Use consistent padding (20px horizontal, 16px vertical)
    - Preserve all existing functionality (QR scanning, book issuing, data processing)
    - _Requirements: 14.1, 14.2, 21.5_

  - [ ]* 24.2 Write widget tests for librarian borrow screen
    - Test borrow functionality preservation
    - Test QR scanning integration
    - _Requirements: 21.5_

- [x] 25. Redesign librarian return screen
  - [ ] 25.1 Update `lib/features/borrow/screens/librarian_return_screen.dart`
    - Update layout with design tokens for spacing
    - Update button styling to match theme
    - Update input field styling to match theme
    - Use StatusBadge for transaction status
    - Use consistent padding (20px horizontal, 16px vertical)
    - Preserve all existing functionality (QR scanning, book returning, fee calculation)
    - _Requirements: 11.7, 14.1, 14.2, 21.5_

  - [ ]* 25.2 Write widget tests for librarian return screen
    - Test return functionality preservation
    - Test fee calculation display
    - Test QR scanning integration
    - _Requirements: 21.5_

- [ ]* 26. Create golden tests for reservation and transaction screens
  - [ ]* 26.1 Create golden tests for reader reservation screen
    - Create golden file for screen with reservations
    - Create golden file for empty state
    - Create golden file for QR dialog
    - _Requirements: 19.1, 19.2_

  - [ ]* 26.2 Create golden tests for reader transactions screen
    - Create golden file for each tab with data
    - Create golden file for empty state
    - _Requirements: 19.3, 19.4_

  - [ ]* 26.3 Create golden tests for librarian screens
    - Create golden file for borrow screen
    - Create golden file for return screen
    - _Requirements: 21.5_

- [x] 27. Checkpoint - Reservation and transaction screens complete
  - Ensure all tests pass
  - Verify reservation flows work identically
  - Verify borrow/return flows work identically
  - Verify QR scanning works correctly
  - Ask user if questions arise


### Phase 6: Screen Redesign - Forms & Management (Week 6)

- [x] 28. Redesign book management forms
  - [x] 28.1 Update `lib/features/books/screens/add_book_screen.dart` (or equivalent)
    - Update form input styling to match InputDecorationTheme
    - Update button styling to match theme
    - Update validation error display with error color
    - Use consistent field spacing (12-16px between fields)
    - Use consistent padding (20px horizontal, 16px vertical)
    - Preserve all existing functionality (form validation, book creation, API calls)
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.7, 5.8, 9.7, 14.1, 14.2, 14.7, 21.4_

  - [ ]* 28.2 Write widget tests for add book screen
    - Test form validation preservation
    - Test form submission functionality
    - Test error display
    - _Requirements: 5.4, 5.7, 9.7_

  - [x] 28.3 Update stock management screen (if separate)
    - Update layout with design tokens for spacing
    - Update button styling to match theme
    - Update input field styling to match theme
    - Use consistent padding (20px horizontal, 16px vertical)
    - Preserve all existing functionality (stock updates, data processing)
    - _Requirements: 14.1, 14.2, 21.4_

  - [ ]* 28.4 Write widget tests for stock management screen
    - Test stock update functionality preservation
    - _Requirements: 21.4_

- [x] 29. Redesign admin management screens
  - [x] 29.1 Update user management screen
    - Update list item styling with consistent padding (12-16px vertical)
    - Display user avatar (circular, appropriate size)
    - Display user name and role with proper typography
    - Update action button styling (primary for promote, error for remove)
    - Use consistent spacing between list items
    - Use 20px horizontal padding
    - Preserve all existing functionality (user promotion, user removal, data loading)
    - _Requirements: 10.4, 10.5, 14.1, 14.2, 14.4, 20.1, 20.2, 20.3, 20.4, 21.7_

  - [ ]* 29.2 Write widget tests for user management screen
    - Test user list display
    - Test promote functionality preservation
    - Test remove functionality preservation
    - _Requirements: 20.1-20.4_

  - [x] 29.3 Update access code screen (if exists)
    - Update list styling with consistent padding
    - Update copy button styling
    - Use consistent spacing
    - Use 20px horizontal padding
    - Preserve all existing functionality (code generation, code copying)
    - _Requirements: 14.1, 14.2, 20.6, 21.7_

  - [ ]* 29.4 Write widget tests for access code screen
    - Test code display
    - Test copy functionality preservation
    - _Requirements: 20.6_

- [x] 30. Redesign profile and settings screens
  - [x] 30.1 Update profile screen
    - Display user avatar (circular, 100x100dp, centered)
    - Display user name and role with proper typography
    - Use card-based layout for information sections
    - Update button styling to match theme
    - Use consistent spacing (32px avatar top margin, 16px bottom margin, 12px between cards)
    - Use 20px horizontal padding
    - Preserve all existing functionality (profile display, sign out, navigation)
    - _Requirements: 14.1, 14.2, 18.1, 18.2, 18.3, 18.6, 21.1_

  - [ ]* 30.2 Write widget tests for profile screen
    - Test profile data display
    - Test sign out functionality preservation
    - Test navigation to settings
    - _Requirements: 18.1-18.6_

  - [x] 30.3 Update settings screen
    - Use grouped list layout for settings options
    - Display leading icons with consistent sizing (24dp)
    - Display title and optional trailing indicator
    - Use consistent list item styling (12-16px vertical padding)
    - Use 20px horizontal padding
    - Preserve all existing functionality (settings navigation, preferences)
    - _Requirements: 10.4, 10.5, 10.6, 10.7, 14.1, 14.2, 14.4, 18.4, 18.5, 21.1_

  - [ ]* 30.4 Write widget tests for settings screen
    - Test settings list display
    - Test navigation to setting details
    - _Requirements: 18.4, 18.5_

- [ ]* 31. Create golden tests for form and management screens
  - [ ]* 31.1 Create golden tests for form screens
    - Create golden file for add book form
    - Create golden file for form with validation errors
    - _Requirements: 5.1-5.8, 9.7_

  - [ ]* 31.2 Create golden tests for admin screens
    - Create golden file for user management list
    - Create golden file for access code screen
    - _Requirements: 20.1-20.6_

  - [ ]* 31.3 Create golden tests for profile and settings
    - Create golden file for profile screen
    - Create golden file for settings screen
    - _Requirements: 18.1-18.6_

- [x] 32. Checkpoint - Form and management screens complete
  - Ensure all tests pass
  - Verify form submission works identically
  - Verify admin actions work identically
  - Verify profile and settings work correctly
  - Ask user if questions arise


### Phase 7: Navigation & Micro-interactions (Week 7)

- [x] 33. Update navigation components
  - [x] 33.1 Update bottom navigation bar styling
    - Use modern icons from Material Icons (or Lucide/Heroicons if available)
    - Use filled variants for active state, outlined variants for inactive state
    - Implement smooth transitions for active indicator (200ms)
    - Ensure consistent styling from BottomNavigationBarTheme
    - Verify touch targets meet 48dp minimum
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 15.1, 15.4, 16.1, 16.2_

  - [ ]* 33.2 Write widget tests for bottom navigation
    - Test tab selection
    - Test active state indicators
    - Test icon display
    - _Requirements: 2.2-2.5_

  - [x] 33.3 Update app bar styling across all screens
    - Ensure consistent elevation from AppBarTheme
    - Ensure consistent background color
    - Ensure consistent title styling
    - Verify all screens use consistent app bar
    - _Requirements: 2.1, 2.6_

  - [ ]* 33.4 Write widget tests for app bar consistency
    - Test app bar styling across multiple screens
    - Test title display
    - _Requirements: 2.1, 2.6_

- [x] 34. Implement state preservation with IndexedStack
  - [x] 34.1 Update main navigation to use IndexedStack
    - Replace existing tab navigation with IndexedStack pattern
    - Ensure tab switching preserves scroll position
    - Ensure tab switching preserves form inputs
    - Test state preservation across all tabs
    - _Requirements: 2.7_

  - [ ]* 34.2 Write property test for navigation state preservation
    - **Property 1: Navigation State Preservation**
    - **Validates: Requirements 2.7**
    - Test tab switching preserves widget state (scroll position, form inputs)
    - Verify state is identical before and after tab switch
    - Tag: `// Feature: modern-ui-redesign, Property 1`

- [x] 35. Implement micro-interactions
  - [x] 35.1 Add card tap feedback
    - Wrap all tappable cards with InkWell
    - Use borderRadius matching card radius
    - Use primary color at 12% opacity for splash
    - Duration: 200ms
    - _Requirements: 3.5, 13.1_

  - [x] 35.2 Add button press feedback
    - Verify all buttons use Material ripple effect (built-in)
    - Ensure button themes provide appropriate feedback
    - Duration: 150ms
    - _Requirements: 4.9, 13.2_

  - [x] 35.3 Add input focus animations
    - Verify TextField focus border transitions smoothly
    - Use 200ms duration with easeInOut curve
    - Ensure focus states use primary color
    - _Requirements: 5.3, 13.4_

  - [ ]* 35.4 Write widget tests for micro-interactions
    - Test card tap feedback
    - Test button press feedback
    - Test input focus animations
    - _Requirements: 13.1-13.4_

- [x] 36. Configure page transitions
  - [x] 36.1 Verify MaterialPageRoute transitions
    - Ensure smooth page transitions (300ms)
    - Use platform-appropriate transitions (slide on Android, fade on iOS)
    - Use easeOut curve
    - Test navigation between all screens
    - _Requirements: 13.3, 13.5, 13.6_

  - [x] 36.2 Verify modal and dialog transitions
    - Ensure dialogs use fade in with scale (0.8 to 1.0)
    - Duration: 250ms with easeOut curve
    - Test all dialogs in the app
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [ ]* 36.3 Write widget tests for page transitions
    - Test navigation transitions
    - Test dialog transitions
    - _Requirements: 13.3, 13.5_

- [x] 37. Verify animation performance
  - [x] 37.1 Test animations on physical devices
    - Verify all animations run at 60fps
    - Check for any performance regressions
    - Profile animation performance if needed
    - Optimize if necessary
    - _Requirements: 13.5, 13.7_

- [x] 38. Checkpoint - Navigation and micro-interactions complete
  - Ensure all tests pass
  - Verify tab switching preserves state
  - Verify all animations are smooth
  - Verify no performance issues
  - Ask user if questions arise


### Phase 8: Polish & Testing (Week 8)

- [x] 39. Visual polish pass
  - [x] 39.1 Audit spacing consistency across all screens
    - Verify all screens use 20px horizontal padding
    - Verify all screens use 16px vertical spacing between sections
    - Verify all cards use 16px internal padding
    - Verify all list items use 12-16px vertical padding
    - Verify all section headers use 24px top margin, 12px bottom margin
    - Verify all button groups use 8-12px spacing
    - Verify all form fields use 12-16px spacing
    - Fix any inconsistencies found
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7, 24.2_

  - [x] 39.2 Audit color usage consistency
    - Verify all screens use colors from AppColors constants
    - Verify no hardcoded color values
    - Verify status colors are used consistently
    - Verify badge colors match design tokens
    - Fix any inconsistencies found
    - _Requirements: 1.1, 1.6, 24.6_

  - [x] 39.3 Audit typography consistency
    - Verify all text uses styles from theme TextTheme
    - Verify page titles use headlineLarge
    - Verify section titles use headlineMedium
    - Verify card titles use headlineSmall
    - Verify body text uses bodyLarge/bodyMedium
    - Verify captions use bodySmall
    - Fix any inconsistencies found
    - _Requirements: 1.2, 1.7, 24.3, 24.7_

  - [x] 39.4 Audit shadow and elevation consistency
    - Verify all cards use elevationSm (1.0)
    - Verify all floating elements use appropriate elevation
    - Verify shadow colors are consistent
    - Fix any inconsistencies found
    - _Requirements: 1.5, 24.1_

  - [x] 39.5 Audit border radius consistency
    - Verify all cards use radiusMd (12px)
    - Verify all buttons use radiusMd (12px)
    - Verify all inputs use radiusMd (12px)
    - Verify all badges use radiusRound (100px)
    - Fix any inconsistencies found
    - _Requirements: 1.4_

  - [x] 39.6 Audit alignment and white space
    - Verify appropriate white space for breathing room
    - Verify consistent alignment (left, center, right) based on content type
    - Verify no harsh borders (use subtle dividers or spacing)
    - Fix any issues found
    - _Requirements: 24.2, 24.3, 24.5_

- [x] 40. Accessibility audit
  - [x] 40.1 Verify touch target sizes
    - Verify all buttons meet 48dp minimum height
    - Verify all list items meet 48dp minimum height for tappable items
    - Verify all icon buttons meet 48x48dp minimum
    - Verify all interactive elements meet 48x48dp minimum
    - Fix any violations found
    - _Requirements: 16.1, 16.2, 16.3, 16.4_

  - [x] 40.2 Verify text contrast ratios
    - Verify body text meets 4.5:1 contrast ratio
    - Verify large text meets 3:1 contrast ratio
    - Verify all text on colored backgrounds meets requirements
    - Use contrast checker tool
    - Fix any violations found
    - _Requirements: 16.5_

  - [x] 40.3 Test with screen reader
    - Enable TalkBack (Android) or VoiceOver (iOS)
    - Navigate through all screens
    - Verify all interactive elements have semantic labels
    - Verify navigation order is logical
    - Add missing labels where needed
    - _Requirements: 16.6_

  - [x] 40.4 Verify visual feedback on touch
    - Verify all interactive elements provide visual feedback
    - Test on physical device
    - Fix any missing feedback
    - _Requirements: 16.6_

- [ ]* 41. Complete property-based test suite
  - [ ]* 41.1 Write property test for search field clear button visibility
    - **Property 4: Search Field Clear Button Visibility**
    - **Validates: Requirements 5.6**
    - Test search field with empty and non-empty text
    - Verify clear button displays only when text is non-empty
    - Tag: `// Feature: modern-ui-redesign, Property 4`

  - [ ]* 41.2 Run all property tests with 100+ iterations
    - Run Property 1: Navigation State Preservation
    - Run Property 2: Library Card Information Completeness
    - Run Property 3: Book Card Information Completeness
    - Run Property 4: Search Field Clear Button Visibility
    - Run Property 5: Conditional Distance Display
    - Run Property 6: Empty State Display
    - Run Property 7: Loading State Display
    - Run Property 8: Reservation Card Information Completeness
    - Run Property 9: Transaction Card Information Completeness
    - Fix any failures found

  - [ ]* 41.3 Verify all property tests pass
    - Ensure all 9 property tests pass consistently
    - Document any edge cases discovered
    - Update tests if needed

- [ ]* 42. Update and verify golden tests
  - [ ]* 42.1 Update all golden files
    - Regenerate golden files for all components
    - Regenerate golden files for all screens
    - Review visual changes
    - Approve new golden files

  - [ ]* 42.2 Run golden test suite
    - Run all golden tests
    - Verify no unexpected visual regressions
    - Fix any issues found

- [ ]* 43. Integration testing
  - [ ]* 43.1 Test critical user flows end-to-end
    - Test authentication flow (sign in, sign up, sign out)
    - Test library discovery and joining flow
    - Test book browsing and reservation flow
    - Test borrow and return flow
    - Test admin management flows
    - Verify all flows work identically to before redesign

  - [ ]* 43.2 Test on multiple devices
    - Test on small screen device (e.g., iPhone SE)
    - Test on medium screen device (e.g., iPhone 14)
    - Test on large screen device (e.g., iPhone 14 Pro Max)
    - Test on Android device
    - Verify consistent appearance and functionality

  - [ ]* 43.3 Verify functionality preservation
    - Verify authentication logic unchanged
    - Verify library joining logic unchanged
    - Verify book browsing and search logic unchanged
    - Verify reservation logic unchanged
    - Verify borrow/return logic unchanged
    - Verify admin features unchanged
    - Verify API calls unchanged
    - Verify routing unchanged
    - Verify state management unchanged
    - _Requirements: 21.1-21.10_

- [x] 44. Performance testing
  - [x] 44.1 Profile app performance
    - Use Flutter DevTools to profile performance
    - Check for any performance regressions
    - Verify app startup time unchanged
    - Verify memory usage unchanged
    - Verify animations run at 60fps
    - _Requirements: 13.7_

  - [x] 44.2 Optimize if needed
    - Optimize any performance issues found
    - Reduce animation complexity if needed
    - Optimize image loading if needed

- [x] 45. Documentation
  - [x] 45.1 Document component usage
    - Create documentation for LibraryCard usage
    - Create documentation for BookCard usage
    - Create documentation for ReservationCard usage
    - Create documentation for TransactionCard usage
    - Create documentation for StatCard usage
    - Create documentation for StatusBadge usage
    - Create documentation for EmptyStateWidget usage
    - Include code examples and screenshots

  - [x] 45.2 Document design token usage
    - Document AppColors constants and usage
    - Document AppDimens constants and usage
    - Document theme configuration
    - Include examples of proper usage

  - [x] 45.3 Create migration guide (optional)
    - Document changes made during redesign
    - Document new component library
    - Document design system
    - Provide guidance for future UI development

- [x] 46. Final checkpoint - UI redesign complete
  - Ensure all tests pass (unit, property, golden, integration)
  - Verify visual consistency across all screens
  - Verify accessibility compliance
  - Verify functionality preservation
  - Verify performance is acceptable
  - Ask user for final review and approval

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation and provide opportunities for user feedback
- Property tests validate universal correctness properties across all inputs
- Unit tests validate specific examples and edge cases
- Golden tests ensure visual consistency and catch regressions
- All implementation tasks preserve existing functionality without modifying business logic
- The 8-week timeline can be adjusted based on team size and priorities
- Phases can be deployed incrementally as they are completed

## Success Criteria

The UI redesign will be considered complete when:

1. All design tokens are implemented and used consistently
2. All component library widgets are implemented and tested
3. All screens are redesigned with new components and styling
4. All 9 property-based tests pass with 100+ iterations
5. All unit tests pass with 80%+ coverage for components
6. All golden tests pass with no unexpected regressions
7. All integration tests pass with functionality preserved
8. All accessibility requirements are met (48dp touch targets, WCAG contrast)
9. All animations are smooth with no performance regressions
10. Visual consistency is achieved across all screens
11. User acceptance testing confirms the redesign meets expectations

## Risk Mitigation

- **Breaking existing functionality**: Comprehensive testing at each phase, never modify business logic, incremental migration with rollback capability
- **Visual inconsistencies**: Use design tokens consistently, golden tests for visual regression, visual polish pass at end
- **Accessibility violations**: Follow design token dimensions, use predefined color combinations, accessibility audit before completion
- **Performance degradation**: Use lightweight animations, performance testing after each phase, profile and optimize if needed
- **Timeline delays**: Prioritize core screens first, can ship incrementally by feature area, buffer time in final polish phase
