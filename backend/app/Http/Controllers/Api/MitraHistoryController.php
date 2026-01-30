<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\ApiToken;
use App\Models\Ride;
use App\Models\CarRide;
use App\Models\BarangRide;
use App\Models\TebenganTitipBarang;
use App\Models\Payment;
use Illuminate\Support\Facades\Log;

class MitraHistoryController extends Controller
{
    public function index(Request $request)
    {
        // Authenticate via bearer token (same method used elsewhere)
        $bearer = $request->bearerToken();
        
        Log::info('MitraHistory: Bearer token received', [
            'has_bearer' => !empty($bearer),
            'bearer_length' => $bearer ? strlen($bearer) : 0
        ]);
        
        if (!$bearer) {
            Log::warning('MitraHistory: No bearer token provided');
            return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
        }

        $hashed = hash('sha256', $bearer);
        $apiToken = ApiToken::where('token', $hashed)->first();
        
        if (!$apiToken) {
            Log::warning('MitraHistory: Invalid token', ['hashed' => substr($hashed, 0, 10) . '...']);
            return response()->json(['success' => false, 'message' => 'Invalid token'], 401);
        }
        
        if ($apiToken->expires_at < now()) {
            Log::warning('MitraHistory: Token expired', [
                'user_id' => $apiToken->user_id,
                'expires_at' => $apiToken->expires_at
            ]);
            return response()->json(['success' => false, 'message' => 'Token expired'], 401);
        }

        $userId = $apiToken->user_id;
        
        Log::info('MitraHistory: Authenticated user', ['user_id' => $userId]);

        // Optional status filter mapping from UI friendly values
        $statusFilter = $request->query('status');
        $statusMap = [
            'selesai' => 'completed',
            'proses' => 'active',
            'dibatalkan' => 'cancelled',
            'kosong' => 'full',
        ];

        $mappedStatus = null;
        if ($statusFilter && isset($statusMap[strtolower($statusFilter)])) {
            $mappedStatus = $statusMap[strtolower($statusFilter)];
        }

        $items = [];

        // Motor rides (tebengan_motor)
        // Include the `user` relation so frontend can read mitra (owner) information
        $rQuery = Ride::with(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra'])
            ->where('user_id', $userId);
        if ($mappedStatus) $rQuery->where('status', $mappedStatus);
        $r = $rQuery->get();
        foreach ($r as $row) {
            // Get all booking_numbers for this ride that actually exist in booking_motor table
            $validBookingNumbers = \App\Models\Booking::where('ride_id', $row->id)
                ->pluck('booking_number')
                ->toArray();
            
            $income = 0;
            if (!empty($validBookingNumbers)) {
                // For each valid booking_number, get only the latest paid payment
                $income = Payment::selectRaw('MAX(id) as latest_payment_id')
                    ->whereIn('booking_number', $validBookingNumbers)
                    ->where('status', 'paid')
                    ->groupBy('booking_number')
                    ->get()
                    ->sum(function($item) {
                        $payment = Payment::find($item->latest_payment_id);
                        return $payment ? $payment->total_amount : 0;
                    });
            }
            
            $rideArr = $row->toArray();
            // Ensure kendaraan_mitra key exists in snake_case for frontend compatibility
            $rideArr['kendaraan_mitra'] = $row->kendaraanMitra ? $row->kendaraanMitra->toArray() : null;
            // Expose seat info both on kendaraan_mitra and on ride as seat_count for frontend
            if ($row->kendaraanMitra && isset($row->kendaraanMitra->seats)) {
                $rideArr['kendaraan_mitra']['seats'] = intval($row->kendaraanMitra->seats);
            }
            // Also include available_seats / seat_count on ride level
            $rideArr['seat_count'] = $row->available_seats ?? $row->availableSeats ?? null;

            // Get first booking with customer data
            $firstBooking = \App\Models\Booking::with('user')
                ->where('ride_id', $row->id)
                ->first();
            
            $bookingNumber = $firstBooking ? $firstBooking->booking_number : null;
            $customerName = null;
            $customerUser = null;
            if ($firstBooking && $firstBooking->user) {
                $customerName = $firstBooking->user->name;
                $customerUser = $firstBooking->user->toArray();
            }

            $items[] = [
                'id' => $row->id,
                'type' => 'motor',
                'ride' => $rideArr,
                'income' => (float) $income,
                'booking_number' => $bookingNumber,
                'customer_name' => $customerName,
                'customer' => $customerUser,
            ];
        }

        // Mobil rides (tebengan_mobil)
        $cQuery = CarRide::with(['originLocation', 'destinationLocation', 'kendaraanMitra', 'user'])
            ->where('user_id', $userId);
        if ($mappedStatus) $cQuery->where('status', $mappedStatus);
        $c = $cQuery->get();
        foreach ($c as $row) {
            // Get all booking_numbers for this ride that actually exist in booking_mobil table
            $validBookingNumbers = \App\Models\BookingMobil::where('ride_id', $row->id)
                ->pluck('booking_number')
                ->toArray();
            
            $income = 0;
            if (!empty($validBookingNumbers)) {
                // For each valid booking_number, get only the latest paid payment
                $income = Payment::selectRaw('MAX(id) as latest_payment_id')
                    ->whereIn('booking_number', $validBookingNumbers)
                    ->where('status', 'paid')
                    ->groupBy('booking_number')
                    ->get()
                    ->sum(function($item) {
                        $payment = Payment::find($item->latest_payment_id);
                        return $payment ? $payment->total_amount : 0;
                    });
            }
            
            $rideArr = $row->toArray();
            $rideArr['kendaraan_mitra'] = $row->kendaraanMitra ? $row->kendaraanMitra->toArray() : null;
            if ($row->kendaraanMitra && isset($row->kendaraanMitra->seats)) {
                $rideArr['kendaraan_mitra']['seats'] = intval($row->kendaraanMitra->seats);
            }
            $rideArr['seat_count'] = $row->available_seats ?? $row->availableSeats ?? null;

            // Get first booking with customer data
            $firstBooking = \App\Models\BookingMobil::with('user')
                ->where('ride_id', $row->id)
                ->first();
            
            $bookingNumber = $firstBooking ? $firstBooking->booking_number : null;
            $customerName = null;
            $customerUser = null;
            if ($firstBooking && $firstBooking->user) {
                $customerName = $firstBooking->user->name;
                $customerUser = $firstBooking->user->toArray();
            }

            $items[] = [
                'id' => $row->id,
                'type' => 'mobil',
                'ride' => $rideArr,
                'income' => (float) $income,
                'booking_number' => $bookingNumber,
                'customer_name' => $customerName,
                'customer' => $customerUser,
            ];
        }

        // Barang rides
        // Barang rides - include `user` as well to expose mitra information
        $bQuery = BarangRide::with(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra'])
            ->where('user_id', $userId);
        if ($mappedStatus) $bQuery->where('status', $mappedStatus);
        $b = $bQuery->get();
        foreach ($b as $row) {
            // Get bookings for this barang ride
            $bookings = \App\Models\BookingBarang::where('ride_id', $row->id)
                ->pluck('booking_number')
                ->toArray();
            
            $income = 0;
            if (!empty($bookings)) {
                // For each booking_number, take only the latest paid payment to avoid duplicates
                $income = Payment::selectRaw('MAX(id) as latest_payment_id')
                    ->whereIn('booking_number', $bookings)
                    ->where('status', 'paid')
                    ->groupBy('booking_number')
                    ->get()
                    ->sum(function($item) {
                        $payment = Payment::find($item->latest_payment_id);
                        return $payment ? $payment->total_amount : 0;
                    });
            }
            
            $rideArr = $row->toArray();
            $rideArr['kendaraan_mitra'] = $row->kendaraanMitra ? $row->kendaraanMitra->toArray() : null;
            if ($row->kendaraanMitra && isset($row->kendaraanMitra->seats)) {
                $rideArr['kendaraan_mitra']['seats'] = intval($row->kendaraanMitra->seats);
            }
            $rideArr['seat_count'] = $row->available_seats ?? $row->availableSeats ?? null;

            // Get first booking with customer data
            $firstBooking = \App\Models\BookingBarang::with('user')
                ->where('ride_id', $row->id)
                ->first();
            
            $bookingNumber = $firstBooking ? $firstBooking->booking_number : null;
            $customerName = null;
            $customerUser = null;
            if ($firstBooking && $firstBooking->user) {
                $customerName = $firstBooking->user->name;
                $customerUser = $firstBooking->user->toArray();
            }

            $items[] = [
                'id' => $row->id,
                'type' => 'barang',
                'ride' => $rideArr,
                'income' => (float) $income,
                'booking_number' => $bookingNumber,
                'customer_name' => $customerName,
                'customer' => $customerUser,
            ];
        }

        // Titip Barang (if any)
        // Titip Barang - include `user` relation
        $tQuery = TebenganTitipBarang::with(['user', 'originLocation', 'destinationLocation', 'kendaraanMitra'])
            ->where('user_id', $userId);
        if ($mappedStatus) $tQuery->where('status', $mappedStatus);
        $t = $tQuery->get();
        foreach ($t as $row) {
            // Get bookings for this titip barang ride
            $bookings = \App\Models\BookingTitipBarang::where('ride_id', $row->id)
                ->pluck('booking_number')
                ->toArray();
            
            $income = 0;
            if (!empty($bookings)) {
                // For each booking_number, take only the latest paid payment to avoid duplicates
                $income = Payment::selectRaw('MAX(id) as latest_payment_id')
                    ->whereIn('booking_number', $bookings)
                    ->where('status', 'paid')
                    ->groupBy('booking_number')
                    ->get()
                    ->sum(function($item) {
                        $payment = Payment::find($item->latest_payment_id);
                        return $payment ? $payment->total_amount : 0;
                    });
            }
            
            $rideArr = $row->toArray();
            $rideArr['kendaraan_mitra'] = $row->kendaraanMitra ? $row->kendaraanMitra->toArray() : null;
            if ($row->kendaraanMitra && isset($row->kendaraanMitra->seats)) {
                $rideArr['kendaraan_mitra']['seats'] = intval($row->kendaraanMitra->seats);
            }
            $rideArr['seat_count'] = $row->available_seats ?? $row->availableSeats ?? null;

            // Get first booking with customer data
            $firstBooking = \App\Models\BookingTitipBarang::with('user')
                ->where('ride_id', $row->id)
                ->first();
            
            $bookingNumber = $firstBooking ? $firstBooking->booking_number : null;
            $customerName = null;
            $customerUser = null;
            if ($firstBooking && $firstBooking->user) {
                $customerName = $firstBooking->user->name;
                $customerUser = $firstBooking->user->toArray();
            }

            $items[] = [
                'id' => $row->id,
                'type' => 'titip',
                'ride' => $rideArr,
                'income' => (float) $income,
                'booking_number' => $bookingNumber,
                'customer_name' => $customerName,
                'customer' => $customerUser,
            ];
        }

        // Sort by departure_date desc, then time desc (fallback created_at)
        usort($items, function ($a, $b) {
            $ad = $a['ride']['departure_date'] ?? $a['ride']['created_at'] ?? null;
            $bd = $b['ride']['departure_date'] ?? $b['ride']['created_at'] ?? null;
            if ($ad == $bd) {
                $at = $a['ride']['departure_time'] ?? '';
                $bt = $b['ride']['departure_time'] ?? '';
                return strcmp($bt, $at);
            }
            return strcmp($bd, $ad);
        });

        return response()->json(['success' => true, 'data' => $items]);
    }
}
