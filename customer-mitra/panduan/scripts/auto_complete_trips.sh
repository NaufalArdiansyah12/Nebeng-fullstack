#!/bin/bash

# Script to automatically complete trips and update driver balance
# This will find bookings that are past their departure time and mark them as completed

cd "$(dirname "$0")"

echo "=========================================="
echo "Auto Complete Trips & Update Balance"
echo "=========================================="
echo ""

php artisan tinker --execute="
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use App\Models\Payment;
use App\Models\User;
use Carbon\Carbon;

\$now = Carbon::now();
\$completed = 0;

// Function to complete booking and update balance
function completeBookingWithBalance(\$booking, \$bookingType = 'motor') {
    if (!in_array(\$booking->status, ['completed', 'selesai', 'cancelled', 'canceled'])) {
        // Find payment
        \$payment = Payment::where('booking_number', \$booking->booking_number)
            ->where('status', 'paid')
            ->first();
        
        if (\$payment) {
            // Get driver user_id based on booking type
            \$driverId = null;
            if (in_array(\$bookingType, ['motor', 'mobil', 'barang', 'titip'])) {
                \$driverId = \$booking->ride ? \$booking->ride->user_id : null;
            }
            
            if (\$driverId) {
                \$driver = User::find(\$driverId);
                if (\$driver) {
                    // Update status
                    \$oldStatus = \$booking->status;
                    if (in_array(\$bookingType, ['barang', 'titip'])) {
                        \$booking->status = 'selesai';
                    } else {
                        \$booking->status = 'completed';
                    }
                    \$booking->save();
                    
                    // Add balance
                    \$oldBalance = \$driver->balance;
                    \$driver->balance = (\$driver->balance ?? 0) + \$payment->amount;
                    \$driver->save();
                    
                    echo '✓ Completed: ' . \$booking->booking_number . ' (' . \$bookingType . ')' . PHP_EOL;
                    echo '  Driver: ' . \$driver->name . PHP_EOL;
                    echo '  Amount: Rp ' . number_format(\$payment->amount, 0, ',', '.') . PHP_EOL;
                    echo '  Balance: Rp ' . number_format(\$oldBalance, 0, ',', '.') . ' → Rp ' . number_format(\$driver->balance, 0, ',', '.') . PHP_EOL;
                    echo PHP_EOL;
                    
                    return true;
                }
            }
        }
    }
    return false;
}

// 1. Complete Motor bookings
echo '=== Nebeng Motor ===' . PHP_EOL;
\$motorBookings = Booking::with(['ride'])
    ->whereHas('ride', function(\$q) use (\$now) {
        \$q->where(function(\$query) use (\$now) {
            \$query->whereRaw(\"CONCAT(departure_date, ' ', departure_time) < ?\", [\$now]);
        });
    })
    ->whereNotIn('status', ['completed', 'cancelled'])
    ->get();

foreach (\$motorBookings as \$booking) {
    if (completeBookingWithBalance(\$booking, 'motor')) {
        \$completed++;
    }
}

// 2. Complete Mobil bookings
echo '=== Nebeng Mobil ===' . PHP_EOL;
\$mobilBookings = BookingMobil::with(['ride'])
    ->whereHas('ride', function(\$q) use (\$now) {
        \$q->where(function(\$query) use (\$now) {
            \$query->whereRaw(\"CONCAT(departure_date, ' ', departure_time) < ?\", [\$now]);
        });
    })
    ->whereNotIn('status', ['completed', 'cancelled'])
    ->get();

foreach (\$mobilBookings as \$booking) {
    if (completeBookingWithBalance(\$booking, 'mobil')) {
        \$completed++;
    }
}

// 3. Complete Barang bookings
echo '=== Nebeng Barang ===' . PHP_EOL;
\$barangBookings = BookingBarang::with(['ride'])
    ->whereHas('ride', function(\$q) use (\$now) {
        \$q->where(function(\$query) use (\$now) {
            \$query->whereRaw(\"CONCAT(departure_date, ' ', departure_time) < ?\", [\$now]);
        });
    })
    ->whereNotIn('status', ['selesai', 'cancelled', 'dibatalkan'])
    ->get();

foreach (\$barangBookings as \$booking) {
    if (completeBookingWithBalance(\$booking, 'barang')) {
        \$completed++;
    }
}

// 4. Complete Titip Barang bookings
echo '=== Titip Barang ===' . PHP_EOL;
\$titipBookings = BookingTitipBarang::with(['tebengan'])
    ->whereHas('tebengan', function(\$q) use (\$now) {
        \$q->where(function(\$query) use (\$now) {
            \$query->whereRaw(\"CONCAT(departure_date, ' ', departure_time) < ?\", [\$now]);
        });
    })
    ->whereNotIn('status', ['selesai', 'cancelled', 'dibatalkan'])
    ->get();

foreach (\$titipBookings as \$booking) {
    if (completeBookingWithBalance(\$booking, 'titip')) {
        \$completed++;
    }
}

echo '========================================' . PHP_EOL;
echo 'Total completed: ' . \$completed . ' bookings' . PHP_EOL;
echo '========================================' . PHP_EOL;
"

echo ""
echo "Done!"
