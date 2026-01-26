# Booking Detail - Refactored Structure

## 📁 Folder Structure

```
lib/screens/customer/riwayat/booking_detail/
├── utils/
│   ├── booking_formatters.dart    # Formatting functions (date, price, status)
│   └── countdown_helper.dart      # Countdown timer management
└── widgets/
    ├── booking_header.dart        # Header with gradient and status badge
    ├── countdown_section.dart     # Countdown display for waiting status
    ├── driver_info_card.dart      # Driver information with actions
    ├── in_progress_layout.dart    # Complete layout for in_progress status
    ├── location_card.dart         # Location display (origin/destination)
    ├── map_placeholder.dart       # Map placeholder with pattern
    ├── passenger_card.dart        # Passenger information cards
    ├── price_card.dart            # Price breakdown display
    └── route_card.dart            # Route information display
```

## 🎯 Purpose

This refactoring splits the large `booking_detail_riwayat_page.dart` (1709 lines) into smaller, manageable, and reusable components:

### Benefits:
- ✅ **Better Maintainability**: Each component is in its own file
- ✅ **Reusability**: Components can be used in other parts of the app
- ✅ **Easier Testing**: Individual components can be tested separately
- ✅ **Team Collaboration**: Multiple developers can work on different components
- ✅ **Clear Separation**: Logic, formatting, and UI are separated

## 📦 Components Overview

### Utils (Helper Classes)

#### `BookingFormatters`
Static utility class for formatting:
- `formatDateTime(dateStr, timeStr)` - Format date and time to Indonesian format
- `formatDateOnly(dateStr)` - Format date only
- `formatPrice(price)` - Format price to Rupiah
- `getStatusText(status)` - Get human-readable status text

#### `CountdownHelper`
Manages countdown timers:
- `start({departureDate, departureTime, onUpdate})` - Start countdown
- `cancel()` - Cancel countdown
- `dispose()` - Clean up resources

### Widgets (UI Components)

#### `BookingHeader`
Displays the booking type header with gradient background and status badge.

**Props:**
- `title`: String - Booking title (Nebeng Motor, Nebeng Mobil, etc.)
- `headerIcon`: IconData - Icon for booking type
- `accentColor`: Color - Theme color
- `currentStatus`: String - Current booking status

#### `CountdownSection`
Shows countdown to departure time (only for waiting status).

**Props:**
- `rawDate`: String - Departure date
- `rawTime`: String - Departure time
- `timeUntilDeparture`: Duration? - Time remaining

#### `DriverInfoCard`
Displays driver information with call and chat actions.

**Props:**
- `driverName`: String
- `driverPhoto`: String (URL)
- `plateNumber`: String
- `accentColor`: Color
- `onCallPressed`: VoidCallback?
- `onChatPressed`: VoidCallback?

#### `RouteCard`
Shows origin and destination with times.

**Props:**
- `origin`: String
- `destination`: String
- `departureTime`: String
- `dateOnly`: String

#### `PassengerCard` & `DetailedPassengerCard`
Display passenger information (simple or detailed for mobil bookings).

#### `PriceCard`
Shows price breakdown and booking details.

**Props:**
- `pricePerSeat`: String
- `seats`: String
- `totalPrice`: String
- `bookingType`: String
- `booking`: Map<String, dynamic>

#### `LocationCard`
Reusable location display component.

**Props:**
- `icon`: IconData
- `iconColor`: Color
- `title`: String
- `subtitle`: String
- `onVisitPressed`: VoidCallback?

#### `MapPlaceholder`
Map placeholder with animated marker (for in_progress status).

**Props:**
- `statusText`: String (default: 'Driver dalam perjalanan')

#### `InProgressLayout`
Complete layout for trips in progress with map and live tracking.

**Props:**
- `booking`: Map<String, dynamic>
- `trackingData`: Map<String, dynamic>?
- `currentDot`: int

## 🔄 Main Page Flow

The main `booking_detail_riwayat_page.dart` now:
1. Manages state and data fetching
2. Determines which layout to show (in_progress vs default)
3. Uses imported components to build UI
4. Handles navigation and user interactions

## 📝 Usage Example

```dart
import 'booking_detail/widgets/countdown_section.dart';
import 'booking_detail/utils/booking_formatters.dart';

// Use countdown section
CountdownSection(
  rawDate: '2026-01-25',
  rawTime: '14:30:00',
  timeUntilDeparture: Duration(hours: 2),
)

// Use formatter
final formattedPrice = BookingFormatters.formatPrice(50000);
// Output: Rp50.000
```

## 🔧 Migration Notes

- Original file backed up as `booking_detail_riwayat_page_backup.dart`
- No breaking changes to public API
- All imports from other files remain unchanged
- Component files can be further customized per requirements

## 🚀 Future Improvements

- Add unit tests for utilities
- Add widget tests for components
- Extract more common patterns into shared widgets
- Create theme file for colors and styles
- Add loading states to components
- Implement proper error handling in each component

---
**Refactored on:** January 23, 2026
**Original Lines:** 1709
**Refactored Structure:** 11 component files + 1 main page
