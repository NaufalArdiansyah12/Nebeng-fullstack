#!/bin/bash

# Script to manually complete ALL pending bookings (for testing purposes)
# This will complete all bookings regardless of departure time

cd "$(dirname "$0")"

echo "=========================================="
echo "Complete ALL Pending Trips (Testing Mode)"
echo "=========================================="
echo ""
echo "WARNING: This will complete ALL pending bookings!"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Processing..."
echo ""

php artisan tinker --execute="
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use App\Models\Payment;
use App\Models\User;
use Carbon\Carbon;

\$completed = 0;

function completeBooking(\$booking, \$bookingType = 'motor') {
    if (!in_array(\$booking->status, ['completed', 'selesai', 'cancelled', 'canceled'])) {
        \$payment = Payment::where('booking_number', \$booking->booking_number)
            ->where('status', 'paid')
            ->first();
        
        if (\$payment) {
            \$driverId = null;
            if (in_array(\$bookingType, ['motor', 'mobil', 'barang', 'titip'])) {
                \$driverId = \$booking->ride ? \$booking->ride->user_id : null;
            }
            
            if (\$driverId) {
                \$driver = User::find(\$driverId);
                if (\$driver) {
                    if (in_array(\$bookingType, ['barang', 'titip'])) {
                        \$booking->status = 'selesai';
                    } else {
                        \$booking->status = 'completed';
                    }
                    \$booking->save();
                    
                    \$oldBalance = \$driver->balance;
                    \$driver->balance = (\$driver->balance ?? 0) + \$payment->amount;
                    \$driver->save();
                    
                    echo '✓ ' . \$booking->booking_number . ' - ' . \$driver->name . ' +Rp ' . number_format(\$payment->amount, 0, ',', '.') . PHP_EOL;
                    return true;
                }
            }
        }
    }
    return false;
}

\$motorBookings = Booking::whereNotIn('status', ['completed', 'cancelled'])->get();
foreach (\$motorBookings as \$booking) {
    if (completeBooking(\$booking, 'motor')) \$completed++;
}

\$mobilBookings = BookingMobil::whereNotIn('status', ['completed', 'cancelled'])->get();
foreach (\$mobilBookings as \$booking) {
    if (completeBooking(\$booking, 'mobil')) \$completed++;
}

\$barangBookings = BookingBarang::whereNotIn('status', ['selesai', 'cancelled'])->get();
foreach (\$barangBookings as \$booking) {
    if (completeBooking(\$booking, 'barang')) \$completed++;
}

\$titipBookings = BookingTitipBarang::whereNotIn('status', ['selesai', 'cancelled'])->get();
foreach (\$titipBookings as \$booking) {
    if (completeBooking(\$booking, 'titip')) \$completed++;
}

echo PHP_EOL;
echo 'Total: ' . \$completed . ' bookings completed' . PHP_EOL;
"

echo ""
echo "=========================================="
echo "Done!"
echo "=========================================="
