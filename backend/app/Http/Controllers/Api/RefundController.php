<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Refund;
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class RefundController extends Controller
{
    /**
     * Get refund eligibility for a booking
     */
    public function checkEligibility(Request $request, $bookingId)
    {
        $bookingType = $request->query('type', 'motor');
        
        $booking = $this->findBooking($bookingId, $bookingType);
        
        if (!$booking) {
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak ditemukan'
            ], 404);
        }

        // Check if already has refund request
        $existingRefund = Refund::where('booking_id', $bookingId)
            ->where('booking_type', $bookingType)
            ->whereIn('status', ['pending', 'approved', 'processing'])
            ->first();

        if ($existingRefund) {
            return response()->json([
                'success' => false,
                'message' => 'Refund sudah pernah diajukan untuk booking ini',
                'data' => ['has_refund' => true, 'refund' => $existingRefund]
            ], 400);
        }

        // Calculate refund amount (80% of total)
        $totalAmount = $booking->ride->price ?? 0;
        if ($bookingType === 'mobil') {
            $totalAmount = ($booking->ride->price ?? 0) * ($booking->seats ?? 1);
        }
        
        $adminFee = $totalAmount * 0.20; // 20% admin fee
        $refundAmount = $totalAmount - $adminFee;

        // Get departure date for eligibility check
        $ride = $booking->ride;
        $departureDate = $ride->departure_date ?? '';
        $departureTime = $ride->departure_time ?? '';
        
        $canRefund = false;
        $reason = '';
        
        try {
            if ($departureTime) {
                $dateTimeParts = explode(' ', $departureTime);
                $time = count($dateTimeParts) > 1 ? $dateTimeParts[1] : '00:00:00';
                $departureDateTime = \DateTime::createFromFormat('Y-m-d H:i:s', "$departureDate $time");
            } else {
                $departureDateTime = \DateTime::createFromFormat('Y-m-d', $departureDate);
            }
            
            $now = new \DateTime();
            $diff = $departureDateTime->diff($now);
            $hoursUntilDeparture = ($diff->days * 24) + $diff->h;
            
            if ($hoursUntilDeparture >= 120) { // 5 days
                $canRefund = true;
            } else {
                $reason = 'Refund hanya dapat dilakukan minimal 5 hari sebelum keberangkatan';
            }
        } catch (\Exception $e) {
            $reason = 'Tidak dapat menghitung waktu keberangkatan';
        }

        return response()->json([
            'success' => true,
            'data' => [
                'can_refund' => $canRefund,
                'reason' => $reason,
                'total_amount' => $totalAmount,
                'admin_fee' => $adminFee,
                'refund_amount' => $refundAmount,
                'booking' => $booking->load('ride', 'user'),
            ]
        ]);
    }

    /**
     * Submit refund request
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'booking_id' => 'required|integer',
            'booking_type' => 'required|string|in:motor,mobil,barang,titip',
            'refund_reason' => 'required|string',
            'bank_name' => 'required|string|max:255',
            'account_number' => 'required|string|max:50',
            'account_holder_name' => 'required|string|max:255',
            'user_id' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Validation error',
                'errors' => $validator->errors(),
            ], 422);
        }

        $booking = $this->findBooking($request->booking_id, $request->booking_type);
        
        if (!$booking) {
            return response()->json([
                'success' => false,
                'message' => 'Booking tidak ditemukan'
            ], 404);
        }

        // Check if already has pending refund
        $existingRefund = Refund::where('booking_id', $request->booking_id)
            ->where('booking_type', $request->booking_type)
            ->whereIn('status', ['pending', 'approved', 'processing'])
            ->first();

        if ($existingRefund) {
            return response()->json([
                'success' => false,
                'message' => 'Refund sudah pernah diajukan untuk booking ini'
            ], 400);
        }

        // Calculate amounts
        $totalAmount = $booking->ride->price ?? 0;
        if ($request->booking_type === 'mobil') {
            $totalAmount = ($booking->ride->price ?? 0) * ($booking->seats ?? 1);
        }
        
        $adminFee = $totalAmount * 0.20;
        $refundAmount = $totalAmount - $adminFee;

        $refund = Refund::create([
            'user_id' => $request->user_id,
            'booking_id' => $request->booking_id,
            'booking_type' => $request->booking_type,
            'refund_reason' => $request->refund_reason,
            'total_amount' => $totalAmount,
            'refund_amount' => $refundAmount,
            'admin_fee' => $adminFee,
            'bank_name' => $request->bank_name,
            'account_number' => $request->account_number,
            'account_holder_name' => $request->account_holder_name,
            'status' => 'pending',
            'submitted_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pengajuan refund berhasil',
            'data' => $refund
        ], 201);
    }

    /**
     * Get user's refund history
     */
    public function index(Request $request)
    {
        $userId = $request->query('user_id');
        
        if (!$userId) {
            return response()->json([
                'success' => false,
                'message' => 'User ID required'
            ], 400);
        }

        $refunds = Refund::where('user_id', $userId)
            ->with('user')
            ->orderBy('created_at', 'desc')
            ->get();

        // Load booking data for each refund
        $refunds->each(function($refund) {
            $booking = $this->findBooking($refund->booking_id, $refund->booking_type);
            if ($booking) {
                $booking->load('ride');
                $refund->booking_data = $booking;
            }
        });

        return response()->json([
            'success' => true,
            'data' => $refunds
        ]);
    }

    /**
     * Get refund detail
     */
    public function show($id)
    {
        $refund = Refund::with('user')->find($id);

        if (!$refund) {
            return response()->json([
                'success' => false,
                'message' => 'Refund tidak ditemukan'
            ], 404);
        }

        $booking = $this->findBooking($refund->booking_id, $refund->booking_type);
        if ($booking) {
            $booking->load('ride', 'user');
            $refund->booking_data = $booking;
        }

        return response()->json([
            'success' => true,
            'data' => $refund
        ]);
    }

    /**
     * Helper to find booking across different tables
     */
    private function findBooking($bookingId, $bookingType)
    {
        switch ($bookingType) {
            case 'motor':
                return Booking::find($bookingId);
            case 'mobil':
                return BookingMobil::find($bookingId);
            case 'barang':
                return BookingBarang::find($bookingId);
            case 'titip':
                return BookingTitipBarang::find($bookingId);
            default:
                return null;
        }
    }
}
