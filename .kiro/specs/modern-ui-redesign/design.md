# Design Document: Modern UI Redesign

## Overview

This design document specifies the comprehensive UI redesign for the library management Flutter application. The redesign focuses exclusively on visual presentation and user interface components while preserving all existing functionality, business logic, API calls, and routing.

### Design Goals

1. Create a modern, premium mobile application aesthetic
2. Establish a cohesive design system with standardized tokens
3. Implement reusable component library for consistency
4. Enhance visual hierarchy and readability
5. Improve user experience through subtle animations and micro-interactions
6. Maintain accessibility standards with proper touch targets and contrast ratios
7. Preserve all existing functionality without modification

### Design Principles

- **Consistency**: Use design tokens and reusable components throughout
- **Clarity**: Clear visual hierarchy with appropriate typography and spacing
- **Elegance**: Subtle shadows, smooth cards, and refined color palette
- **Accessibility**: Minimum 48dp touch targets and WCAG contrast ratios
- **Performance**: Lightweight animations that don't impact responsiveness

### Scope

**In Scope:**
- Design system foundation (colors, typography, spacing, shadows)
- Theme configuration and Material Design component themes
- Reusable widget library (cards, buttons, inputs, badges)
- Screen layout redesigns for all existing screens
- Micro-interactions and animations
- Visual polish and refinement

**Out of Scope:**
- Authentication logic modifications
- Business logic changes
- API communication changes
- Routing or navigation structure changes
- State management modifications
- New feature development


## Architecture

### Design System Architecture

The design system follows a token-based architecture with three layers:

```
┌─────────────────────────────────────────┐
│         Application Layer               │
│  (Screens, Features, Custom Widgets)    │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│       Component Library Layer           │
│  (Reusable Widgets: Cards, Buttons,     │
│   Inputs, Badges, Empty States)         │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         Theme Layer                     │
│  (ThemeData, Material Component Themes) │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│       Design Tokens Layer               │
│  (Colors, Typography, Spacing, Shadows) │
└─────────────────────────────────────────┘
```

### File Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Color palette tokens
│   │   ├── app_dimens.dart          # Spacing and sizing tokens
│   │   └── app_text_styles.dart     # Typography tokens (new)
│   ├── theme/
│   │   └── app_theme.dart           # ThemeData configuration
│   └── widgets/
│       ├── cards/
│       │   ├── library_card.dart
│       │   ├── book_card.dart
│       │   ├── reservation_card.dart
│       │   ├── transaction_card.dart
│       │   └── stat_card.dart
│       ├── buttons/
│       │   └── (use Material buttons with theme)
│       ├── inputs/
│       │   └── (use Material inputs with theme)
│       ├── badges/
│       │   └── status_badge.dart
│       └── empty_states/
│           └── empty_state_widget.dart
├── features/
│   └── [existing feature structure preserved]
└── shared/
    └── [existing shared structure preserved]
```

### Navigation Architecture

The app uses a shell navigation pattern with:
- **AppBar**: Top navigation with consistent styling
- **BottomNavigationBar**: Primary navigation with 3-5 tabs
- **IndexedStack**: Preserves state across tab switches
- **MaterialPageRoute**: Standard page transitions

```dart
Scaffold(
  appBar: AppBar(...),
  body: IndexedStack(
    index: _currentIndex,
    children: [
      Screen1(),
      Screen2(),
      Screen3(),
    ],
  ),
  bottomNavigationBar: BottomNavigationBar(...),
)
```


## Components and Interfaces

### Design Tokens

#### Color Palette

**Primary Colors:**
```dart
static const Color primary = Color(0xFF1E3A8A);        // Deep blue
static const Color primaryLight = Color(0xFF3B82F6);   // Bright blue
static const Color primaryDark = Color(0xFF1E2A5E);    // Navy blue
static const Color accent = Color(0xFF3B82F6);         // Accent blue
```

**Background & Surface:**
```dart
static const Color background = Color(0xFFF8FAFC);     // Light gray-blue
static const Color surface = Color(0xFFFFFFFF);        // White
static const Color surfaceVariant = Color(0xFFF1F5F9); // Light gray
```

**Text Colors:**
```dart
static const Color textPrimary = Color(0xFF111827);    // Near black
static const Color textSecondary = Color(0xFF6B7280);  // Medium gray
static const Color textTertiary = Color(0xFF9CA3AF);   // Light gray
```

**Status Colors:**
```dart
static const Color success = Color(0xFF059669);        // Green
static const Color warning = Color(0xFFF59E0B);        // Amber
static const Color error = Color(0xFFDC2626);          // Red
static const Color info = Color(0xFF3B82F6);           // Blue
```

**Borders & Dividers:**
```dart
static const Color border = Color(0xFFE5E7EB);         // Light gray
static const Color divider = Color(0xFFF3F4F6);        // Very light gray
```

**Badge Colors:**
```dart
// Available (Green)
static const Color availableBadge = Color(0xFFDCFCE7);
static const Color availableBadgeText = Color(0xFF166534);

// Unavailable (Red)
static const Color unavailableBadge = Color(0xFFFEE2E2);
static const Color unavailableBadgeText = Color(0xFF991B1B);

// Pending (Yellow)
static const Color pendingBadge = Color(0xFFFEF3C7);
static const Color pendingBadgeText = Color(0xFF92400E);
```

#### Typography System

**Font Family:** Inter (fallback: Roboto)

**Text Styles:**
```dart
// Page Title - Used for main screen titles
headlineLarge: TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
  letterSpacing: -0.5,
  height: 1.3,
)

// Section Title - Used for major sections
headlineMedium: TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
  letterSpacing: -0.4,
  height: 1.3,
)

// Card Title - Used for card headers
headlineSmall: TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
  letterSpacing: -0.3,
  height: 1.3,
)

// Subtitle - Used for subsections
titleLarge: TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: AppColors.textPrimary,
  letterSpacing: -0.2,
)

// Body Text - Primary content
bodyLarge: TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
  color: AppColors.textPrimary,
  height: 1.5,
)

// Secondary Text - Supporting content
bodyMedium: TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: AppColors.textSecondary,
  height: 1.5,
)

// Caption - Small labels and metadata
bodySmall: TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: AppColors.textTertiary,
  height: 1.5,
)
```

#### Spacing System (4px Grid)

```dart
static const double xs = 4.0;    // Extra small spacing
static const double sm = 8.0;    // Small spacing
static const double md = 16.0;   // Medium spacing (base unit)
static const double lg = 24.0;   // Large spacing
static const double xl = 32.0;   // Extra large spacing
static const double xxl = 48.0;  // Extra extra large spacing
```

#### Border Radius

```dart
static const double radiusSm = 8.0;      // Small corners
static const double radiusMd = 12.0;     // Medium corners (default)
static const double radiusLg = 16.0;     // Large corners
static const double radiusXl = 24.0;     // Extra large corners
static const double radiusRound = 100.0; // Fully rounded (pills, circles)
```

#### Elevation & Shadows

```dart
static const double elevationNone = 0.0;  // No shadow
static const double elevationSm = 1.0;    // Subtle shadow for cards
static const double elevationMd = 2.0;    // Medium shadow for floating elements
static const double elevationLg = 4.0;    // Strong shadow for modals/dialogs
```

Shadow configuration in CardTheme:
```dart
shadowColor: Colors.black.withOpacity(0.06)  // Soft, subtle shadows
```

#### Icon Sizes

```dart
static const double iconSm = 18.0;   // Small icons (inline with text)
static const double iconMd = 24.0;   // Standard icons
static const double iconLg = 32.0;   // Large icons (headers, empty states)
static const double iconXl = 48.0;   // Extra large icons (empty states)
```

#### Component Dimensions

```dart
// Touch targets (accessibility)
static const double minTouchTarget = 48.0;

// Buttons
static const double buttonHeight = 52.0;
static const double buttonRadius = 12.0;

// Inputs
static const double inputHeight = 52.0;

// Cards
static const double cardPadding = 16.0;

// Page padding
static const double pagePaddingH = 20.0;  // Horizontal
static const double pagePaddingV = 16.0;  // Vertical
```


### Component Library

#### Card Components

**1. LibraryCard**

Displays library information in discovery and list views.

```dart
class LibraryCard extends StatelessWidget {
  final LibraryModel library;
  final double? distance;
  final bool isJoined;
  final VoidCallback? onTap;
  
  // Visual structure:
  // ┌─────────────────────────────────┐
  // │ [Icon] Library Name      [Badge]│
  // │        Description              │
  // │        👥 Members  📚 Books     │
  // │        📍 Distance (if available)│
  // └─────────────────────────────────┘
}
```

**Properties:**
- Border radius: `AppDimens.radiusMd` (12px)
- Padding: `AppDimens.cardPadding` (16px)
- Elevation: `AppDimens.elevationSm` (1.0)
- Background: `AppColors.surface`
- Tap feedback: InkWell with splash color

**Content Requirements:**
- Library icon with gradient background (48x48dp)
- Library name (headlineSmall style)
- Description (bodyMedium style, max 2 lines)
- Member count with icon
- Book count with icon
- Distance indicator (conditional, shown when location available)
- Join status badge (Joined/Free/Fee amount)

**2. BookCard**

Displays book information in grid layouts.

```dart
class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;
  
  // Visual structure:
  // ┌──────────────┐
  // │              │
  // │  Book Cover  │
  // │   (3:4 ratio)│
  // │              │
  // ├──────────────┤
  // │ Title        │
  // │ Author       │
  // │ 🏛️ Library   │
  // │ [Badge]      │
  // └──────────────┘
}
```

**Properties:**
- Border radius: `AppDimens.radiusMd` (12px)
- Padding: `AppDimens.sm` (8px)
- Elevation: `AppDimens.elevationSm` (1.0)
- Background: `AppColors.surface`
- Cover aspect ratio: 3:4
- Tap feedback: InkWell with splash color

**Content Requirements:**
- Book cover image with placeholder
- Title (titleMedium style, max 2 lines, ellipsis)
- Author (bodyMedium style, max 1 line, ellipsis)
- Library name with icon (bodySmall style)
- Availability badge (Available/Unavailable/Reserved)

**3. ReservationCard**

Displays reservation information.

```dart
class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback? onViewQR;
  final VoidCallback? onCancel;
  
  // Visual structure:
  // ┌─────────────────────────────────┐
  // │ [Cover] Book Title       [Badge]│
  // │         Author                  │
  // │         📅 Reserved: Date       │
  // │         ⏰ Expires: Date        │
  // │         [View QR] [Cancel]      │
  // └─────────────────────────────────┘
}
```

**Properties:**
- Border radius: `AppDimens.radiusMd` (12px)
- Padding: `AppDimens.cardPadding` (16px)
- Elevation: `AppDimens.elevationSm` (1.0)
- Background: `AppColors.surface`

**Content Requirements:**
- Book cover thumbnail (60x80dp)
- Book title and author
- Reservation date
- Expiry date
- Status badge (Active/Expired/Collected)
- Action buttons (View QR, Cancel)

**4. TransactionCard**

Displays borrow/return transaction information.

```dart
class TransactionCard extends StatelessWidget {
  final BorrowTransactionModel transaction;
  
  // Visual structure:
  // ┌─────────────────────────────────┐
  // │ [Cover] Book Title       [Badge]│
  // │         Author                  │
  // │         📅 Borrowed: Date       │
  // │         📅 Due: Date            │
  // │         💰 Fee: Amount (if any) │
  // └─────────────────────────────────┘
}
```

**Properties:**
- Border radius: `AppDimens.radiusMd` (12px)
- Padding: `AppDimens.cardPadding` (16px)
- Elevation: `AppDimens.elevationSm` (1.0)
- Background: `AppColors.surface`

**Content Requirements:**
- Book cover thumbnail (60x80dp)
- Book title and author
- Borrow date
- Due date
- Return date (if returned)
- Fee amount (if applicable)
- Status badge (Active/Overdue/Returned)

**5. StatCard**

Displays dashboard statistics.

```dart
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? color;
  
  // Visual structure:
  // ┌──────────────┐
  // │ [Icon]       │
  // │              │
  // │ 1,234        │
  // │ Label        │
  // └──────────────┘
}
```

**Properties:**
- Border radius: `AppDimens.radiusMd` (12px)
- Padding: `AppDimens.cardPadding` (16px)
- Elevation: `AppDimens.elevationSm` (1.0)
- Background: `AppColors.surface`
- Aspect ratio: 1:1 (square)

**Content Requirements:**
- Optional icon (iconLg size)
- Value (headlineMedium style)
- Label (bodyMedium style)

#### Button Components

All buttons use Material Design components with theme configuration:

**1. Primary Button (ElevatedButton)**
- Background: `AppColors.primary`
- Foreground: White
- Height: 52dp
- Border radius: 12px
- No elevation (flat design)

**2. Secondary Button (TextButton)**
- Foreground: `AppColors.accent`
- No background
- Height: 52dp

**3. Outline Button (OutlinedButton)**
- Foreground: `AppColors.primary`
- Border: `AppColors.border` (1.5px)
- Height: 52dp
- Border radius: 12px

**4. Danger Button (ElevatedButton with custom color)**
- Background: `AppColors.error`
- Foreground: White
- Height: 52dp
- Border radius: 12px

**5. Icon Button (IconButton)**
- Size: 48x48dp (minimum touch target)
- Icon size: 24dp
- Color: `AppColors.textSecondary`

#### Input Components

All inputs use Material Design TextField with theme configuration:

**1. Standard TextField**
- Filled style with `AppColors.surfaceVariant` background
- Border radius: 12px
- No border (borderless filled)
- Focus border: `AppColors.primary` (1.5px)
- Error border: `AppColors.error` (1.5px)
- Height: 52dp
- Padding: 16px horizontal, 14px vertical

**2. Search Field**
- Same as TextField
- Prefix icon: Search icon
- Suffix icon: Clear button (when text present)
- Hint text: "Search..."

**3. Dropdown Field (DropdownButtonFormField)**
- Same styling as TextField
- Dropdown icon: Arrow down

#### Badge Component

```dart
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type; // available, unavailable, pending, custom
  final Color? customColor;
  final Color? customTextColor;
  
  // Visual: [Label]
}
```

**Properties:**
- Shape: Rounded pill (`radiusRound`)
- Padding: 8px horizontal, 4px vertical
- Font size: 11px
- Font weight: Bold (w600)
- Text transform: Uppercase

**Variants:**
- Available: Green background, dark green text
- Unavailable: Red background, dark red text
- Pending: Yellow background, dark yellow text
- Custom: Provided colors

#### Empty State Component

```dart
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  // Visual structure:
  // ┌─────────────────┐
  // │                 │
  // │     [Icon]      │
  // │                 │
  // │     Title       │
  // │    Message      │
  // │                 │
  // │   [Action Btn]  │
  // │                 │
  // └─────────────────┘
}
```

**Properties:**
- Icon size: 64dp
- Icon color: `AppColors.textTertiary`
- Title: headlineSmall style
- Message: bodyMedium style, centered
- Optional action button
- Centered vertically and horizontally


## Data Models

The UI redesign does not introduce new data models. All existing models are preserved:

### Existing Models (Preserved)

**LibraryModel** (`lib/features/library/models/library_model.dart`)
- Contains: id, name, description, memberCount, bookCount, location, membershipFee
- Used by: LibraryCard, Library screens

**BookModel** (`lib/features/books/models/book_model.dart`)
- Contains: id, title, author, coverUrl, libraryId, libraryName, totalStock, availableStock
- Used by: BookCard, Book screens

**ReservationModel** (`lib/features/reservations/models/reservation_model.dart`)
- Contains: id, bookId, userId, status, createdAt, expiresAt, qrCode
- Used by: ReservationCard, Reservation screens

**BorrowTransactionModel** (`lib/features/borrow/models/borrow_transaction_model.dart`)
- Contains: id, bookId, userId, borrowDate, dueDate, returnDate, status, fee
- Used by: TransactionCard, Transaction screens

**UserModel** (existing)
- Contains: id, name, email, role, avatar
- Used by: Profile screens, Admin screens

### Component Props Interfaces

While Flutter doesn't have formal interfaces, components accept these parameter patterns:

**LibraryCard Props:**
```dart
{
  required LibraryModel library,
  double? distance,
  required bool isJoined,
  VoidCallback? onTap,
}
```

**BookCard Props:**
```dart
{
  required BookModel book,
  VoidCallback? onTap,
}
```

**ReservationCard Props:**
```dart
{
  required ReservationModel reservation,
  VoidCallback? onViewQR,
  VoidCallback? onCancel,
}
```

**TransactionCard Props:**
```dart
{
  required BorrowTransactionModel transaction,
}
```

**StatCard Props:**
```dart
{
  required String label,
  required String value,
  IconData? icon,
  Color? color,
}
```

**StatusBadge Props:**
```dart
{
  required String label,
  required BadgeType type,
  Color? customColor,
  Color? customTextColor,
}
```

**EmptyStateWidget Props:**
```dart
{
  required IconData icon,
  required String title,
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Navigation State Preservation

*For any* tab in the bottom navigation, when switching away from that tab and then returning to it, the tab's widget state (scroll position, form inputs, etc.) should be preserved and identical to the state before switching.

**Validates: Requirements 2.7**

### Property 2: Library Card Information Completeness

*For any* LibraryModel with all required fields populated, when rendered as a LibraryCard, the resulting widget should display the library name, description, member count, book count, and join status.

**Validates: Requirements 3.6, 7.3**

### Property 3: Book Card Information Completeness

*For any* BookModel with all required fields populated, when rendered as a BookCard, the resulting widget should display the book cover (or placeholder), title, author, library name, and availability status badge.

**Validates: Requirements 3.7**

### Property 4: Search Field Clear Button Visibility

*For any* search field widget, when the text input is non-empty, a clear button should be visible in the suffix position; when the text input is empty, no clear button should be displayed.

**Validates: Requirements 5.6**

### Property 5: Conditional Distance Display

*For any* LibraryCard, when the distance parameter is provided (non-null), the distance indicator should be displayed; when the distance parameter is null, no distance indicator should be shown.

**Validates: Requirements 7.4**

### Property 6: Empty State Display

*For any* list or grid view, when the data source is empty (zero items), an EmptyStateWidget should be displayed with an appropriate icon, title, and message; when the data source contains items, the list/grid content should be displayed instead.

**Validates: Requirements 10.1**

### Property 7: Loading State Display

*For any* screen with asynchronous data loading, when the loading state is true, a centered CircularProgressIndicator should be displayed; when the loading state is false, the content should be displayed.

**Validates: Requirements 12.1**

### Property 8: Reservation Card Information Completeness

*For any* ReservationModel with all required fields populated, when rendered as a ReservationCard, the resulting widget should display the book information, reservation status badge, reservation date, and expiry date.

**Validates: Requirements 19.1**

### Property 9: Transaction Card Information Completeness

*For any* BorrowTransactionModel with all required fields populated, when rendered as a TransactionCard, the resulting widget should display the book information, borrow date, due date, status badge, and fee amount (if applicable).

**Validates: Requirements 19.3**


## Error Handling

### Design System Error Handling

**Missing Design Tokens:**
- All design tokens are compile-time constants
- Missing tokens will cause compilation errors
- No runtime error handling needed

**Theme Configuration Errors:**
- Theme is configured at app initialization
- Invalid theme configuration will cause app startup failure
- Use Flutter's built-in error reporting

### Component Error Handling

**Missing Required Props:**
- Use `required` keyword for mandatory parameters
- Dart's null safety prevents null reference errors
- Compilation will fail if required props are missing

**Image Loading Errors:**
- Book covers and avatars should use `errorBuilder` parameter
- Display placeholder icon when image fails to load
- Use `CachedNetworkImage` with error widget

```dart
CachedNetworkImage(
  imageUrl: book.coverUrl,
  placeholder: (context, url) => Icon(Icons.book),
  errorWidget: (context, url, error) => Icon(Icons.broken_image),
)
```

**Empty or Null Data:**
- Use null-aware operators (`?.`, `??`)
- Provide default values for optional fields
- Display empty states when data is unavailable

**Conditional Rendering:**
- Use explicit null checks before rendering conditional UI
- Provide fallback UI for missing optional data

```dart
if (distance != null) {
  Text('${distance.toStringAsFixed(1)} km away')
}
```

### Animation Error Handling

**Animation Controller Disposal:**
- Always dispose animation controllers in `dispose()` method
- Use `SingleTickerProviderStateMixin` or `TickerProviderStateMixin`
- Prevent memory leaks from undisposed controllers

**Animation State Errors:**
- Check widget mounted state before calling `setState` in animation callbacks
- Use `if (mounted)` guard before state updates

```dart
_controller.addListener(() {
  if (mounted) {
    setState(() {});
  }
});
```

### Accessibility Error Handling

**Touch Target Violations:**
- Ensure all interactive elements meet 48dp minimum
- Use `SizedBox` or `Container` to enforce minimum size
- Wrap small icons in larger touch targets

**Contrast Ratio Violations:**
- Use predefined color combinations from design tokens
- All token colors meet WCAG AA standards
- Avoid custom color combinations without verification

### State Management Error Handling

**Provider Errors:**
- Existing provider error handling is preserved
- UI redesign does not modify provider logic
- Display error states using existing error handling patterns

**Navigation Errors:**
- Existing navigation error handling is preserved
- UI redesign does not modify routing logic
- Use existing error screens and fallbacks


## Testing Strategy

### Dual Testing Approach

The UI redesign requires both unit tests and property-based tests to ensure correctness:

**Unit Tests:**
- Verify specific examples and edge cases
- Test component rendering with known data
- Test user interactions (taps, input changes)
- Test conditional rendering logic
- Test integration between components

**Property-Based Tests:**
- Verify universal properties across all inputs
- Test components with randomly generated data
- Ensure properties hold for all valid inputs
- Provide comprehensive input coverage

Both testing approaches are complementary and necessary for comprehensive coverage. Unit tests catch concrete bugs with specific examples, while property tests verify general correctness across all possible inputs.

### Property-Based Testing Configuration

**Library Selection:** Use the `flutter_test` package with custom property test helpers, or integrate a Dart property testing library like `test_api` with custom generators.

**Test Configuration:**
- Minimum 100 iterations per property test (due to randomization)
- Each property test must reference its design document property
- Tag format: `// Feature: modern-ui-redesign, Property {number}: {property_text}`

**Example Property Test Structure:**

```dart
testWidgets('Property 2: Library Card Information Completeness', (tester) async {
  // Feature: modern-ui-redesign, Property 2: Library card displays all required information
  
  for (int i = 0; i < 100; i++) {
    final library = generateRandomLibrary();
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LibraryCard(
            library: library,
            isJoined: false,
          ),
        ),
      ),
    );
    
    // Verify all required information is present
    expect(find.text(library.name), findsOneWidget);
    expect(find.text(library.description), findsOneWidget);
    expect(find.textContaining(library.memberCount.toString()), findsOneWidget);
    expect(find.textContaining(library.bookCount.toString()), findsOneWidget);
    expect(find.byType(StatusBadge), findsOneWidget);
  }
});
```

### Unit Testing Strategy

**Component Tests:**
- Test each card component with specific data examples
- Test badge component with each status type
- Test empty state component with various configurations
- Test button interactions and callbacks
- Test input field focus and validation states

**Widget Tests:**
- Test screen layouts with mock data
- Test navigation interactions
- Test conditional rendering (empty states, loading states)
- Test responsive behavior within mobile viewport

**Integration Tests:**
- Test complete user flows with redesigned UI
- Verify functionality preservation
- Test navigation between redesigned screens
- Test state preservation across tab switches

### Visual Regression Testing

**Approach:**
- Use Flutter's golden file testing for visual regression
- Create golden files for each major component
- Create golden files for each screen layout
- Run golden tests in CI/CD pipeline

**Golden Test Examples:**
```dart
testWidgets('LibraryCard golden test', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: LibraryCard(
          library: mockLibrary,
          isJoined: false,
        ),
      ),
    ),
  );
  
  await expectLater(
    find.byType(LibraryCard),
    matchesGoldenFile('goldens/library_card.png'),
  );
});
```

### Accessibility Testing

**Semantic Tests:**
- Verify all interactive elements have semantic labels
- Test screen reader navigation order
- Verify button and link labels are descriptive

**Touch Target Tests:**
- Verify all interactive elements meet 48dp minimum
- Test with `debugPaintPointersEnabled` flag
- Measure actual rendered sizes in widget tests

**Contrast Tests:**
- Verify text contrast ratios meet WCAG AA standards
- Test with color blindness simulators
- Verify status colors are distinguishable

### Manual Testing Checklist

**Visual Polish:**
- [ ] All screens use consistent spacing
- [ ] All cards have consistent shadows and radius
- [ ] All buttons have consistent styling
- [ ] All inputs have consistent styling
- [ ] Typography hierarchy is clear
- [ ] Colors match design tokens
- [ ] Icons are consistent throughout

**Interactions:**
- [ ] All buttons provide visual feedback
- [ ] All cards provide tap feedback (if tappable)
- [ ] All inputs show focus states
- [ ] All animations are smooth (150-300ms)
- [ ] Tab switching preserves state
- [ ] Navigation transitions are smooth

**Functionality Preservation:**
- [ ] Authentication flows work identically
- [ ] Library joining works identically
- [ ] Book browsing and search work identically
- [ ] Reservation creation works identically
- [ ] Borrow/return transactions work identically
- [ ] Admin features work identically
- [ ] All API calls function identically
- [ ] All navigation routes work identically

**Accessibility:**
- [ ] All interactive elements are at least 48dp
- [ ] All text meets contrast requirements
- [ ] Screen reader navigation is logical
- [ ] All images have alt text or semantic labels
- [ ] Focus indicators are visible

### Test Coverage Goals

- **Unit Test Coverage:** 80%+ for new component library
- **Widget Test Coverage:** 70%+ for redesigned screens
- **Property Test Coverage:** All 9 correctness properties implemented
- **Golden Test Coverage:** All major components and screens
- **Integration Test Coverage:** All critical user flows

### Continuous Integration

**Pre-commit:**
- Run unit tests
- Run widget tests
- Run property tests
- Check formatting and linting

**CI Pipeline:**
- Run all tests
- Run golden tests
- Generate coverage report
- Build app for Android and iOS
- Run integration tests on emulators


## Implementation Strategy

### Phase 1: Design System Foundation (Week 1)

**Objective:** Establish design tokens and theme configuration

**Tasks:**
1. Update `app_colors.dart` with refined color palette
2. Update `app_dimens.dart` with complete spacing and sizing tokens
3. Create `app_text_styles.dart` for typography constants (optional, can use theme)
4. Update `app_theme.dart` with comprehensive ThemeData configuration
5. Configure all Material component themes
6. Test theme application across existing screens
7. Verify no visual regressions in existing functionality

**Deliverables:**
- Updated design token files
- Updated theme configuration
- Theme applied globally in `main.dart`

**Testing:**
- Visual inspection of all screens with new theme
- Verify existing functionality works identically
- Check for any layout breaks or styling issues

### Phase 2: Component Library Development (Week 2)

**Objective:** Create reusable widget library

**Tasks:**
1. Create `lib/core/widgets/cards/` directory structure
2. Implement `LibraryCard` widget
3. Implement `BookCard` widget
4. Implement `ReservationCard` widget
5. Implement `TransactionCard` widget
6. Implement `StatCard` widget
7. Create `lib/core/widgets/badges/` directory
8. Implement `StatusBadge` widget
9. Create `lib/core/widgets/empty_states/` directory
10. Implement `EmptyStateWidget`
11. Write unit tests for all components
12. Write property tests for card information completeness
13. Create golden files for visual regression testing

**Deliverables:**
- Complete component library
- Unit tests for all components
- Property tests for correctness properties 2, 3, 8, 9
- Golden test files

**Testing:**
- Unit tests with specific data examples
- Property tests with random data generation
- Golden tests for visual regression
- Manual testing of component variations

### Phase 3: Screen Redesign - Discovery & Browsing (Week 3)

**Objective:** Redesign book and library discovery screens

**Tasks:**
1. Redesign `discover_libraries_screen.dart`
   - Replace existing UI with LibraryCard components
   - Implement search bar with new styling
   - Add "My Libraries" chip section
   - Implement empty state
   - Implement loading state
2. Redesign `browse_books_screen.dart`
   - Replace existing UI with BookCard components
   - Implement 2-column grid layout
   - Implement search bar with new styling
   - Add category filter chips
   - Implement empty state
   - Implement loading state
3. Redesign `library_detail_screen.dart`
   - Update layout with new spacing and styling
   - Use design tokens for all dimensions
4. Redesign `book_detail_screen.dart`
   - Update layout with new spacing and styling
   - Use StatusBadge for availability
   - Use design tokens for all dimensions
5. Test all screens for functionality preservation
6. Write widget tests for conditional rendering
7. Write property tests for empty and loading states

**Deliverables:**
- Redesigned discovery and browsing screens
- Widget tests for screens
- Property tests for properties 6, 7
- Golden tests for screen layouts

**Testing:**
- Verify search functionality works identically
- Verify navigation works identically
- Verify data loading works identically
- Test empty states display correctly
- Test loading states display correctly

### Phase 4: Screen Redesign - Dashboards (Week 4)

**Objective:** Redesign dashboard screens for all user roles

**Tasks:**
1. Redesign `reader_home_screen.dart`
   - Implement stat cards for reader metrics
   - Update layout with new spacing
   - Use design tokens throughout
2. Redesign `librarian_dashboard_screen.dart`
   - Implement stat cards for librarian metrics
   - Add quick action buttons
   - Update layout with new spacing
3. Redesign admin dashboard (if separate screen exists)
   - Implement stat cards for admin metrics
   - Add quick action buttons
   - Update layout with new spacing
4. Test all dashboards for functionality preservation
5. Write widget tests for dashboard layouts
6. Create golden tests for dashboards

**Deliverables:**
- Redesigned dashboard screens
- Widget tests for dashboards
- Golden tests for dashboard layouts

**Testing:**
- Verify all metrics display correctly
- Verify quick actions work identically
- Verify navigation from dashboards works
- Test with various data scenarios

### Phase 5: Screen Redesign - Reservations & Transactions (Week 5)

**Objective:** Redesign reservation and transaction screens

**Tasks:**
1. Redesign `reader_reservation_screen.dart`
   - Replace existing UI with ReservationCard components
   - Implement empty state
   - Implement loading state
   - Update QR dialog styling
2. Redesign `librarian_reservation_scanner.dart`
   - Update QR scanner overlay styling
   - Update instructions styling
3. Redesign `reader_transactions_screen.dart`
   - Replace existing UI with TransactionCard components
   - Implement tab navigation styling
   - Implement empty states for each tab
   - Implement loading states
4. Redesign `librarian_borrow_screen.dart`
   - Update layout with new styling
   - Use design tokens throughout
5. Redesign `librarian_return_screen.dart`
   - Update layout with new styling
   - Use design tokens throughout
6. Test all screens for functionality preservation
7. Write widget tests for reservation and transaction screens
8. Write property tests for card information completeness

**Deliverables:**
- Redesigned reservation and transaction screens
- Widget tests for screens
- Property tests for properties 8, 9
- Golden tests for screen layouts

**Testing:**
- Verify reservation creation works identically
- Verify QR code generation works identically
- Verify borrow/return flows work identically
- Test empty and loading states
- Test tab navigation and state preservation

### Phase 6: Screen Redesign - Forms & Management (Week 6)

**Objective:** Redesign form screens and admin management

**Tasks:**
1. Redesign `add_book_screen.dart`
   - Update form styling with new input theme
   - Update button styling
   - Update validation error display
2. Redesign `stock_management_screen.dart`
   - Update layout with new styling
   - Use design tokens throughout
3. Redesign admin management screens
   - Update user management list styling
   - Update action button styling
   - Use design tokens throughout
4. Redesign profile and settings screens
   - Update profile layout
   - Update settings list styling
   - Use design tokens throughout
5. Test all screens for functionality preservation
6. Write widget tests for form screens
7. Create golden tests for all screens

**Deliverables:**
- Redesigned form and management screens
- Widget tests for screens
- Golden tests for screen layouts

**Testing:**
- Verify form submission works identically
- Verify validation works identically
- Verify admin actions work identically
- Test all user flows end-to-end

### Phase 7: Navigation & Micro-interactions (Week 7)

**Objective:** Implement navigation shell and animations

**Tasks:**
1. Update bottom navigation bar styling
   - Use modern icons
   - Implement active state indicators
   - Add smooth transitions
2. Update app bar styling across all screens
   - Ensure consistent elevation and colors
   - Update title styling
3. Implement IndexedStack for state preservation
   - Test tab switching preserves state
   - Write property test for state preservation
4. Add micro-interactions
   - Card tap feedback (InkWell)
   - Button press feedback (ripple)
   - Input focus animations
5. Add page transitions
   - Configure MaterialPageRoute transitions
   - Ensure smooth animations (200-300ms)
6. Test all navigation flows
7. Write property test for navigation state preservation

**Deliverables:**
- Updated navigation components
- Micro-interactions implemented
- Property test for property 1
- Navigation flow tests

**Testing:**
- Test tab switching preserves scroll position
- Test tab switching preserves form inputs
- Test navigation transitions are smooth
- Test all navigation routes work correctly
- Verify no performance issues from animations

### Phase 8: Polish & Testing (Week 8)

**Objective:** Final polish and comprehensive testing

**Tasks:**
1. Visual polish pass
   - Check spacing consistency across all screens
   - Check color usage consistency
   - Check typography consistency
   - Check shadow and elevation consistency
2. Accessibility audit
   - Verify all touch targets meet 48dp minimum
   - Verify all text meets contrast requirements
   - Test with screen reader
   - Add missing semantic labels
3. Property test implementation
   - Implement all 9 property tests
   - Run tests with 100+ iterations each
   - Fix any failures
4. Golden test updates
   - Update all golden files
   - Verify visual consistency
5. Integration testing
   - Test all critical user flows end-to-end
   - Verify functionality preservation
   - Test on multiple devices/screen sizes
6. Performance testing
   - Check for any performance regressions
   - Optimize animations if needed
   - Check memory usage
7. Documentation
   - Document component usage
   - Document design token usage
   - Create style guide (optional)

**Deliverables:**
- Polished UI across all screens
- Complete test suite (unit, property, golden, integration)
- Accessibility compliance
- Performance optimization
- Documentation

**Testing:**
- Run complete test suite
- Manual testing on physical devices
- Accessibility testing with screen reader
- Performance profiling
- User acceptance testing

### Migration Approach

**Incremental Migration:**
- Migrate screens one at a time
- Keep old and new screens side by side during development
- Use feature flags if needed for gradual rollout
- Test each screen thoroughly before moving to next

**Functionality Preservation:**
- Never modify business logic during UI changes
- Keep all provider logic unchanged
- Keep all repository logic unchanged
- Keep all service logic unchanged
- Keep all model logic unchanged
- Only modify widget tree and styling

**Rollback Strategy:**
- Use version control branches for each phase
- Keep old UI code until new UI is fully tested
- Have rollback plan for each phase
- Monitor for issues after each deployment

### File Organization

**New Files:**
```
lib/core/widgets/
├── cards/
│   ├── library_card.dart
│   ├── book_card.dart
│   ├── reservation_card.dart
│   ├── transaction_card.dart
│   └── stat_card.dart
├── badges/
│   └── status_badge.dart
└── empty_states/
    └── empty_state_widget.dart
```

**Modified Files:**
```
lib/core/
├── constants/
│   ├── app_colors.dart (updated)
│   └── app_dimens.dart (updated)
└── theme/
    └── app_theme.dart (updated)

lib/features/
├── library/screens/ (all screens updated)
├── books/screens/ (all screens updated)
├── reservations/screens/ (all screens updated)
├── borrow/screens/ (all screens updated)
├── admin/screens/ (all screens updated)
└── profile/screens/ (all screens updated)
```

**Preserved Files:**
- All model files unchanged
- All provider files unchanged
- All repository files unchanged
- All service files unchanged
- All routing files unchanged

### Risk Mitigation

**Risk: Breaking existing functionality**
- Mitigation: Comprehensive testing at each phase
- Mitigation: Never modify business logic
- Mitigation: Incremental migration with rollback capability

**Risk: Visual inconsistencies**
- Mitigation: Use design tokens consistently
- Mitigation: Golden tests for visual regression
- Mitigation: Visual polish pass at end

**Risk: Accessibility violations**
- Mitigation: Follow design token dimensions (48dp minimum)
- Mitigation: Use predefined color combinations
- Mitigation: Accessibility audit before completion

**Risk: Performance degradation**
- Mitigation: Use lightweight animations
- Mitigation: Performance testing after each phase
- Mitigation: Profile and optimize if needed

**Risk: Timeline delays**
- Mitigation: Prioritize core screens first
- Mitigation: Can ship incrementally by feature area
- Mitigation: Buffer time in final polish phase

### Success Criteria

**Visual Quality:**
- [ ] All screens use design tokens consistently
- [ ] All components match design specifications
- [ ] Visual hierarchy is clear and consistent
- [ ] Spacing and alignment are consistent
- [ ] Colors and typography are consistent

**Functionality:**
- [ ] All existing features work identically
- [ ] No regressions in business logic
- [ ] All navigation flows work correctly
- [ ] All user interactions work correctly
- [ ] All API calls function correctly

**Testing:**
- [ ] All 9 property tests pass with 100+ iterations
- [ ] Unit test coverage >80% for components
- [ ] Widget test coverage >70% for screens
- [ ] All golden tests pass
- [ ] All integration tests pass

**Accessibility:**
- [ ] All touch targets meet 48dp minimum
- [ ] All text meets WCAG AA contrast ratios
- [ ] Screen reader navigation is logical
- [ ] All interactive elements have semantic labels

**Performance:**
- [ ] No performance regressions
- [ ] Animations are smooth (60fps)
- [ ] App startup time unchanged
- [ ] Memory usage unchanged

**Documentation:**
- [ ] Component usage documented
- [ ] Design token usage documented
- [ ] Migration guide created
- [ ] Testing guide created


## Screen Layout Specifications

### Navigation Shell Structure

All screens use a consistent shell structure:

```dart
Scaffold(
  appBar: AppBar(
    title: Text('Screen Title'),
    // Consistent styling from theme
  ),
  body: IndexedStack(
    index: _currentIndex,
    children: _screens,
  ),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) => setState(() => _currentIndex = index),
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      // Additional items...
    ],
  ),
)
```

### Book Discovery Screen Layout

```
┌─────────────────────────────────────┐
│ ← Browse Books                      │ AppBar
├─────────────────────────────────────┤
│ [Search bar with icon]              │ 20px padding
│                                     │
│ [Chip] [Chip] [Chip] [Chip]        │ Filter chips
│                                     │
│ ┌──────────┐  ┌──────────┐         │
│ │          │  │          │         │
│ │  Book    │  │  Book    │         │ 2-column grid
│ │  Card    │  │  Card    │         │ 16px spacing
│ │          │  │          │         │
│ └──────────┘  └──────────┘         │
│ ┌──────────┐  ┌──────────┐         │
│ │          │  │          │         │
│ │  Book    │  │  Book    │         │
│ │  Card    │  │  Card    │         │
│ │          │  │          │         │
│ └──────────┘  └──────────┘         │
└─────────────────────────────────────┘
```

**Layout Details:**
- Horizontal padding: 20px
- Vertical spacing: 16px
- Grid columns: 2
- Grid spacing: 16px (crossAxisSpacing and mainAxisSpacing)
- Search bar height: 52px
- Chip spacing: 8px

### Library Discovery Screen Layout

```
┌─────────────────────────────────────┐
│ ← Discover Libraries                │ AppBar
├─────────────────────────────────────┤
│ [Search bar with icon]              │ 20px padding
│                                     │
│ My Libraries                        │ Section header
│ [Chip] [Chip] [Chip]                │ Horizontal scroll
│                                     │
│ All Libraries                       │ Section header
│ ┌─────────────────────────────────┐ │
│ │ [Icon] Library Name      [Badge]│ │
│ │        Description              │ │ Library cards
│ │        👥 100  📚 500           │ │ Vertical list
│ │        📍 2.5 km away           │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [Icon] Library Name      [Badge]│ │
│ │        Description              │ │
│ │        👥 50   📚 300           │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Layout Details:**
- Horizontal padding: 20px
- Vertical spacing: 16px
- Card spacing: 12px
- Section header margin: 24px top, 12px bottom
- Chip section height: 40px

### Dashboard Screen Layout (Reader)

```
┌─────────────────────────────────────┐
│ Dashboard                           │ AppBar
├─────────────────────────────────────┤
│ ┌──────────┐  ┌──────────┐         │
│ │ [Icon]   │  │ [Icon]   │         │
│ │          │  │          │         │ Stat cards
│ │   5      │  │   2      │         │ 2-column grid
│ │ Active   │  │ Pending  │         │
│ │ Borrows  │  │ Reserves │         │
│ └──────────┘  └──────────┘         │
│                                     │
│ Quick Actions                       │ Section header
│ ┌─────────────────────────────────┐ │
│ │ Browse Books                    │ │
│ └─────────────────────────────────┘ │ Action buttons
│ ┌─────────────────────────────────┐ │
│ │ My Reservations                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Recent Activity                     │ Section header
│ ┌─────────────────────────────────┐ │
│ │ [Cover] Book Title       [Badge]│ │
│ │         Due in 3 days           │ │ Transaction cards
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Layout Details:**
- Horizontal padding: 20px
- Vertical spacing: 16px
- Stat card grid: 2 columns, 16px spacing
- Stat card aspect ratio: 1:1 (square)
- Action button spacing: 12px
- Section spacing: 24px

### Reservation Screen Layout

```
┌─────────────────────────────────────┐
│ ← My Reservations                   │ AppBar
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [Cover] Book Title       [Badge]│ │
│ │         Author                  │ │
│ │         📅 Reserved: Date       │ │ Reservation cards
│ │         ⏰ Expires: Date        │ │ Vertical list
│ │         [View QR] [Cancel]      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [Cover] Book Title       [Badge]│ │
│ │         Author                  │ │
│ │         📅 Reserved: Date       │ │
│ │         ⏰ Expires: Date        │ │
│ │         [View QR] [Cancel]      │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Layout Details:**
- Horizontal padding: 20px
- Card spacing: 12px
- Cover thumbnail: 60x80dp
- Button spacing: 8px
- Action button height: 40dp

### Transaction Screen Layout

```
┌─────────────────────────────────────┐
│ ← My Books                          │ AppBar
├─────────────────────────────────────┤
│ [Active] [Overdue] [Returned]       │ Tab bar
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ [Cover] Book Title       [Badge]│ │
│ │         Author                  │ │
│ │         📅 Borrowed: Date       │ │ Transaction cards
│ │         📅 Due: Date            │ │ Vertical list
│ │         💰 Fee: $0.00           │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ [Cover] Book Title       [Badge]│ │
│ │         Author                  │ │
│ │         📅 Borrowed: Date       │ │
│ │         📅 Due: Date            │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

**Layout Details:**
- Horizontal padding: 20px
- Card spacing: 12px
- Cover thumbnail: 60x80dp
- Tab bar height: 48dp
- Tab indicator: 2px bottom border

### QR Scanner Screen Layout

```
┌─────────────────────────────────────┐
│ ✕                                   │ Close button
│                                     │
│                                     │
│     ┌─────────────────────┐         │
│     │                     │         │
│     │                     │         │
│     │   Camera Preview    │         │ Scanner area
│     │   with Frame        │         │
│     │                     │         │
│     │                     │         │
│     └─────────────────────┘         │
│                                     │
│  Point camera at QR code            │ Instructions
│                                     │
└─────────────────────────────────────┘
```

**Layout Details:**
- Semi-transparent overlay: black with 0.5 opacity
- Scanner cutout: 250x250dp centered
- Scanner border: 2px white
- Instructions padding: 24px from scanner
- Close button: 48x48dp top-left

### Profile Screen Layout

```
┌─────────────────────────────────────┐
│ Profile                    ⚙️       │ AppBar with settings
├─────────────────────────────────────┤
│                                     │
│          ┌─────────┐                │
│          │         │                │
│          │ Avatar  │                │ User info
│          │         │                │ Centered
│          └─────────┘                │
│                                     │
│         John Doe                    │
│         Reader                      │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ 📧 Email                        │ │
│ │ john@example.com                │ │
│ └─────────────────────────────────┘ │ Info cards
│ ┌─────────────────────────────────┐ │
│ │ 📅 Member Since                 │ │
│ │ January 2024                    │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Sign Out]                          │ Action button
└─────────────────────────────────────┘
```

**Layout Details:**
- Avatar size: 100x100dp
- Avatar margin: 32px top, 16px bottom
- Info card spacing: 12px
- Sign out button margin: 24px top

### Empty State Layout

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│          ┌─────────┐                │
│          │         │                │
│          │  Icon   │                │ Centered
│          │  64dp   │                │
│          │         │                │
│          └─────────┘                │
│                                     │
│         No Items Found              │ Title
│                                     │
│    You don't have any items yet.    │ Message
│    Start by adding your first one.  │
│                                     │
│      [Add Item Button]              │ Optional action
│                                     │
│                                     │
└─────────────────────────────────────┘
```

**Layout Details:**
- Icon size: 64dp
- Icon color: textTertiary
- Title margin: 16px top
- Message margin: 8px top
- Message max width: 280dp
- Button margin: 24px top

### Loading State Layout

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│                                     │
│                                     │
│              ⟳                      │ Centered spinner
│         Loading...                  │
│                                     │
│                                     │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

**Layout Details:**
- Spinner size: 40dp
- Spinner color: primary
- Optional loading text: 16px below spinner
- Centered vertically and horizontally

## Animation Specifications

### Micro-Interactions

**Card Tap Feedback:**
```dart
InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
  child: Card(...),
)
```
- Duration: 200ms
- Effect: Ripple with primary color at 12% opacity

**Button Press Feedback:**
```dart
ElevatedButton(
  onPressed: onPressed,
  child: Text('Button'),
)
```
- Duration: 150ms
- Effect: Material ripple (built-in)
- Scale: Slight elevation change (Material 3)

**Input Focus Animation:**
```dart
TextField(
  decoration: InputDecoration(
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
  ),
)
```
- Duration: 200ms
- Effect: Border color transition
- Curve: easeInOut

### Page Transitions

**Standard Navigation:**
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => NextScreen(),
  ),
)
```
- Duration: 300ms
- Effect: Slide from right (Android) or fade (iOS)
- Curve: easeOut

**Tab Switching:**
```dart
IndexedStack(
  index: _currentIndex,
  children: _screens,
)
```
- Duration: 0ms (instant)
- Effect: No animation (preserves state)
- Bottom nav indicator: 200ms slide animation

**Modal/Dialog:**
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(...),
)
```
- Duration: 250ms
- Effect: Fade in with scale (0.8 to 1.0)
- Curve: easeOut

### Loading Animations

**Circular Progress Indicator:**
```dart
CircularProgressIndicator(
  color: AppColors.primary,
)
```
- Continuous rotation
- No custom animation needed (built-in)

**Pull to Refresh:**
```dart
RefreshIndicator(
  onRefresh: _handleRefresh,
  child: ListView(...),
)
```
- Duration: 300ms
- Effect: Material design refresh indicator
- Color: primary

## Conclusion

This design document provides comprehensive specifications for the modern UI redesign of the library management application. The redesign focuses on visual excellence while preserving all existing functionality.

### Key Deliverables

1. **Design System**: Complete token-based design system with colors, typography, spacing, and shadows
2. **Theme Configuration**: Comprehensive ThemeData with all Material component themes
3. **Component Library**: Reusable widgets for cards, badges, and empty states
4. **Screen Layouts**: Detailed specifications for all screen redesigns
5. **Testing Strategy**: Dual approach with unit tests and property-based tests
6. **Implementation Plan**: 8-week phased approach with clear milestones

### Next Steps

1. Review and approve this design document
2. Begin Phase 1: Design System Foundation
3. Implement component library with tests
4. Progressively redesign screens by feature area
5. Conduct comprehensive testing and polish
6. Deploy with confidence in functionality preservation

The design maintains the existing architecture and business logic while elevating the visual presentation to modern mobile app standards. All 9 correctness properties will be validated through property-based testing to ensure the redesign meets requirements.
