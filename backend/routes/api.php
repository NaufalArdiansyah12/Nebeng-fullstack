<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Hash;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\FcmController;
use App\Http\Controllers\Api\FcmTestController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\RideController;
use App\Http\Controllers\Api\VehicleController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PaymentTestController;
use App\Http\Controllers\TebenganTitipBarangController;
use App\Http\Controllers\Api\MitraHistoryController;
use App\Http\Controllers\Api\TransactionHistoryController;
use App\Http\Controllers\Finance\DashboardController;
use App\Http\Controllers\Finance\BookingController;
use App\Http\Controllers\Finance\UserController as FinanceUserController;
use App\Http\Controllers\Finance\TransactionController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Public API Routes (mounted under /api/v1)
Route::prefix('api/v1')->group(function () {
    // Users endpoint
    Route::get('/users', [UserController::class, 'index']);
    Route::get('/users/{id}', [UserController::class, 'show']);
    Route::post('/users', [UserController::class, 'store']);
    
    // Health check endpoint
    Route::get('/health', function () {
        return response()->json([
            'success' => true,
            'message' => 'API is running',
            'timestamp' => now(),
        ]);
    });

    // Locations (public)
    Route::get('/locations', [LocationController::class, 'index']);
    Route::get('/locations/{id}', [LocationController::class, 'show']);

    // Auth
    Route::post('/auth/login', [\App\Http\Controllers\Api\AuthController::class, 'login']);
    Route::post('/auth/logout', [\App\Http\Controllers\Api\AuthController::class, 'logout']);
    Route::post('/auth/change-password', [\App\Http\Controllers\Api\AuthController::class, 'changePassword']);
    Route::get('/auth/me', [\App\Http\Controllers\Api\AuthController::class, 'me']);
    // Update profile (authenticated via Bearer token)
    Route::post('/auth/update-profile', [\App\Http\Controllers\Api\AuthController::class, 'updateProfile']);

    // PIN Management (requires auth via bearer token)
    Route::get('/pin/check', [\App\Http\Controllers\Api\PinController::class, 'checkPin']);
    Route::post('/pin/create', [\App\Http\Controllers\Api\PinController::class, 'createPin']);
    Route::post('/pin/verify', [\App\Http\Controllers\Api\PinController::class, 'verifyPin']);
    Route::post('/pin/update', [\App\Http\Controllers\Api\PinController::class, 'updatePin']);

    // Rides (public - list and view)
    Route::get('/rides', [RideController::class, 'index']);
    Route::get('/rides/{id}', [RideController::class, 'show']);
    Route::get('/rides/{id}/passengers', [RideController::class, 'getRidePassengers']);
    
    // Reschedule / change schedule endpoints
    Route::get('/bookings/{id}/available-rides', [\App\Http\Controllers\Api\RescheduleController::class, 'availableRides']);
    Route::post('/bookings/{id}/reschedule', [\App\Http\Controllers\Api\RescheduleController::class, 'store']);
    Route::get('/reschedule/{id}', [\App\Http\Controllers\Api\RescheduleController::class, 'show']);
    Route::post('/reschedule/{id}/confirm-payment', [\App\Http\Controllers\Api\RescheduleController::class, 'confirmPayment']);
    Route::put('/reschedule/{id}/approve', [\App\Http\Controllers\Api\RescheduleController::class, 'approve']);
    Route::put('/reschedule/{id}/reject', [\App\Http\Controllers\Api\RescheduleController::class, 'reject']);
    
    // Rides (create - requires auth via bearer token)
    Route::post('/rides', [RideController::class, 'store']);

    // Bookings: customers create a booking (reserve) before payment
    Route::post('/bookings', [\App\Http\Controllers\Api\BookingController::class, 'store']);
    // Authenticated: list current user's bookings (filter by type via ?type=semua|motor|mobil|barang|titip)
    // Note: use bearer token lookup inside controller (project uses custom ApiToken table)
    Route::get('/bookings/my', [\App\Http\Controllers\Api\BookingController::class, 'myBookings']);
    Route::get('/bookings/{id}', [\App\Http\Controllers\Api\BookingController::class, 'show']);
    // Update booking status (customer or driver can update)
    Route::put('/bookings/{id}/status', [\App\Http\Controllers\Api\BookingController::class, 'updateStatus']);
    // Get comprehensive tracking info
    Route::get('/bookings/{id}/tracking', [\App\Http\Controllers\Api\BookingTrackingController::class, 'show']);
    // Driver actions for trip
    Route::post('/bookings/{id}/start-trip', [\App\Http\Controllers\Api\BookingTrackingController::class, 'startTrip']);
    Route::post('/bookings/{id}/complete-trip', [\App\Http\Controllers\Api\BookingTrackingController::class, 'completeTrip']);
    // Accept location updates from drivers for a booking (expects bearer token)
    Route::post('/bookings/{id}/location', [\App\Http\Controllers\Api\BookingLocationController::class, 'store']);
    // Get latest location for a booking (requires bearer token). Supports If-Modified-Since and If-None-Match.
    Route::get('/bookings/{id}/location', [\App\Http\Controllers\Api\BookingLocationController::class, 'show']);

    // Booking Mobil Query & Tracking & Location
    Route::get('/booking-mobil', [\App\Http\Controllers\Api\BookingMobilController::class, 'index']);
    Route::get('/booking-mobil/{id}/tracking', [\App\Http\Controllers\Api\BookingMobilTrackingController::class, 'show']);
    Route::post('/booking-mobil/{id}/start-trip', [\App\Http\Controllers\Api\BookingMobilTrackingController::class, 'startTrip']);
    Route::post('/booking-mobil/{id}/complete-trip', [\App\Http\Controllers\Api\BookingMobilTrackingController::class, 'completeTrip']);
    Route::post('/booking-mobil/{id}/location', [\App\Http\Controllers\Api\BookingMobilLocationController::class, 'store']);
    Route::get('/booking-mobil/{id}/location', [\App\Http\Controllers\Api\BookingMobilLocationController::class, 'show']);

    // Booking Barang Tracking & Location
    Route::get('/booking-barang', [\App\Http\Controllers\Api\BookingBarangController::class, 'index']);
    Route::get('/booking-barang/{id}/tracking', [\App\Http\Controllers\Api\BookingBarangTrackingController::class, 'show']);
    Route::post('/booking-barang/{id}/start-trip', [\App\Http\Controllers\Api\BookingBarangTrackingController::class, 'startTrip']);
    Route::post('/booking-barang/{id}/complete-trip', [\App\Http\Controllers\Api\BookingBarangTrackingController::class, 'completeTrip']);
    Route::post('/booking-barang/{id}/location', [\App\Http\Controllers\Api\BookingBarangLocationController::class, 'store']);
    Route::get('/booking-barang/{id}/location', [\App\Http\Controllers\Api\BookingBarangLocationController::class, 'show']);

    // Booking Titip Barang Tracking & Location
    Route::get('/booking-titip-barang', [\App\Http\Controllers\Api\BookingTitipBarangController::class, 'index']);
    Route::get('/booking-titip-barang/{id}/tracking', [\App\Http\Controllers\Api\BookingTitipBarangTrackingController::class, 'show']);
    Route::post('/booking-titip-barang/{id}/start-trip', [\App\Http\Controllers\Api\BookingTitipBarangTrackingController::class, 'startTrip']);
    Route::post('/booking-titip-barang/{id}/complete-trip', [\App\Http\Controllers\Api\BookingTitipBarangTrackingController::class, 'completeTrip']);
    Route::post('/booking-titip-barang/{id}/location', [\App\Http\Controllers\Api\BookingTitipBarangLocationController::class, 'store']);
    Route::get('/booking-titip-barang/{id}/location', [\App\Http\Controllers\Api\BookingTitipBarangLocationController::class, 'show']);

    // Vehicles (requires auth via bearer token)
    Route::get('/vehicles', [VehicleController::class, 'index']);
    Route::post('/vehicles', [VehicleController::class, 'store']);
    Route::get('/vehicles/{id}', [VehicleController::class, 'show']);
    Route::put('/vehicles/{id}', [VehicleController::class, 'update']);
    Route::delete('/vehicles/{id}', [VehicleController::class, 'destroy']);

    // Payment routes
    Route::post('/payments', [PaymentController::class, 'createPayment']);
    Route::get('/payments/{id}/status', [PaymentController::class, 'checkPaymentStatus']);
    
    // Xendit webhook callback (no auth required)
    Route::post('/payments/webhook', [PaymentController::class, 'webhookCallback']);

    // FCM token update from mobile app (expects bearer token)
    Route::post('/user/fcm-token', [FcmController::class, 'updateToken']);

    // FCM test endpoint (development/debugging)
    Route::post('/test/fcm', [FcmTestController::class, 'sendTest']);

    // Debug endpoint to register fcm token for a user (no auth) - DEVELOPMENT ONLY
    Route::post('/debug/register-fcm', [\App\Http\Controllers\Api\DebugFcmController::class, 'register']);

    // Payment testing routes (development only)
    Route::get('/payments/test/pending', [PaymentTestController::class, 'getPendingPayments']);
    Route::post('/payments/test/{id}/simulate', [PaymentTestController::class, 'simulatePayment']);

    // Tebengan Titip Barang routes
    Route::get('/tebengan-titip-barang', [TebenganTitipBarangController::class, 'index']);
    Route::get('/tebengan-titip-barang/{id}', [TebenganTitipBarangController::class, 'show']);
    Route::post('/tebengan-titip-barang', [TebenganTitipBarangController::class, 'store']);
    Route::put('/tebengan-titip-barang/{id}', [TebenganTitipBarangController::class, 'update']);
    Route::delete('/tebengan-titip-barang/{id}', [TebenganTitipBarangController::class, 'destroy']);
    Route::get('/tebengan-titip-barang/my/list', [TebenganTitipBarangController::class, 'myTebengan']);

    // Mitra: riwayat tebengan (partner history)
    Route::get('/mitra/riwayat', [MitraHistoryController::class, 'index']);

    // Customer: riwayat transaksi (transaction history) - uses custom ApiToken auth
    Route::get('/transactions/history', [TransactionHistoryController::class, 'index']);

    // Rewards (points / merchandise)
    Route::get('/rewards', [\App\Http\Controllers\Api\RewardController::class, 'index']);
    Route::post('/rewards/{id}/redeem', [\App\Http\Controllers\Api\RewardController::class, 'redeem']);
    Route::get('/rewards/my', [\App\Http\Controllers\Api\RewardController::class, 'myRedemptions']);

    // Customer Verification (requires auth via bearer token)
    Route::get('/customer/verification/status', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'getStatus']);
    Route::get('/customer/verification', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'getVerification']);
    Route::post('/customer/verification/upload-face', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'uploadFacePhoto']);
    Route::post('/customer/verification/upload-ktp', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'uploadKtpPhoto']);
    Route::post('/customer/verification/upload-face-ktp', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'uploadFaceKtpPhoto']);
    Route::post('/customer/verification/submit', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'submitVerification']);

    // Admin routes for managing locations (requires auth:sanctum)
    Route::middleware('auth:sanctum')->prefix('admin')->group(function () {
        Route::post('/locations', [LocationController::class, 'store']);
        Route::put('/locations/{id}', [LocationController::class, 'update']);
        Route::delete('/locations/{id}', [LocationController::class, 'destroy']);
    });
});

// =====================================================
// Finance Dashboard Routes (prefix: /api/finance)
// =====================================================
Route::prefix('finance')->group(function () {
    // Password reset routes
    Route::post('/forgot-password', function (Request $request) {
        $request->validate([
            'email' => 'required|email',
        ]);

        $status = Password::sendResetLink(
            $request->only('email')
        );

        if ($status === Password::RESET_LINK_SENT) {
            return response()->json(['message' => 'Link reset password telah dikirim ke email Anda']);
        }

        // Untuk keamanan, selalu kirim pesan sukses meskipun email tidak ditemukan
        // Ini mencegah user enumeration attack
        return response()->json(['message' => 'Jika email terdaftar, link reset password telah dikirim']);
    });

    Route::post('/reset-password', function (Request $request) {
        $request->validate([
            'token' => 'required',
            'email' => 'required|email',
            'password' => 'required|min:6|confirmed',
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->password = Hash::make($password);
                $user->save();
            }
        );

        if ($status === Password::PASSWORD_RESET) {
            return response()->json(['message' => 'Password berhasil direset']);
        }

        if ($status === Password::INVALID_TOKEN) {
            return response()->json(['message' => 'Token tidak valid atau telah kedaluwarsa'], 400);
        }

        if ($status === Password::INVALID_USER) {
            return response()->json(['message' => 'Email tidak ditemukan'], 400);
        }

        return response()->json(['message' => 'Gagal mereset password'], 400);
    });

    // Dashboard routes
    Route::get('/pendapatan', [DashboardController::class, 'getPendapatan']);
    Route::get('/pendapatan/chart', [DashboardController::class, 'getPendapatanChart']);

    // Booking routes
    Route::get('/bookings/chart', [BookingController::class, 'getPesananChart']);
    Route::get('/bookings/transactions', [BookingController::class, 'getAllBookingTransactions']);

    // Transaction routes
    Route::get('/transactions/{id}', [TransactionController::class, 'getById']);

    // User routes
    Route::prefix('users')->group(function () {
        Route::get('/count-by-role', [FinanceUserController::class, 'countByRole']);
        Route::get('/mitra', [FinanceUserController::class, 'getMitraUsers']);
        Route::post('/login', [FinanceUserController::class, 'login']);
        Route::get('/{id}', [FinanceUserController::class, 'getById']);
        Route::get('/profile/{id}', [FinanceUserController::class, 'profile']);
        Route::put('/profile/{id}', [FinanceUserController::class, 'updateProfile']);
        Route::put('/account/{id}', [FinanceUserController::class, 'updateAccount']);
    });
});