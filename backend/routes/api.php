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
use App\Http\Controllers\PosMitra\ProfileController;
use App\Http\Controllers\PosMitra\BerandaController;
use App\Http\Controllers\PosMitra\WithdrawController;


Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Public API Routes (mounted under /api/v1)
Route::prefix('api/v1')->group(function () {

    // =====================================================
    // SHARED / PUBLIC ROUTES
    // =====================================================

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

    // Test conversation creation
    Route::get('/test-conversation', function () {
        try {
            $service = app(\App\Services\PosMitraConversationService::class);
            $result = $service->createTebenganConversations(2, 3, 1, 'motor');

            return response()->json([
                'success' => true,
                'message' => 'Conversation creation tested',
                'result' => $result,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ], 500);
        }
    });

    // Locations (public)
    Route::get('/locations', [LocationController::class, 'index']);
    Route::get('/locations/{id}', [LocationController::class, 'show']);

    // =====================================================
    // AUTHENTICATION & AUTHORIZATION
    // =====================================================

    // Auth
    Route::post('/auth/register', [\App\Http\Controllers\Api\AuthController::class, 'register']);
    Route::post('/auth/login', [\App\Http\Controllers\Api\AuthController::class, 'login']);
    Route::post('/auth/login/posmitra', [\App\Http\Controllers\Api\AuthController::class, 'loginPosMitra']);
    Route::post('/auth/logout', [\App\Http\Controllers\Api\AuthController::class, 'logout']);
    Route::post('/auth/change-password', [\App\Http\Controllers\Api\AuthController::class, 'changePassword']);
    Route::get('/auth/me', [\App\Http\Controllers\Api\AuthController::class, 'me']);
    // Update profile (authenticated via Bearer token)
    Route::post('/auth/update-profile', [\App\Http\Controllers\Api\AuthController::class, 'updateProfile']);

    // =====================================================
    // USER BALANCE & SAVED DATA
    // =====================================================

    // Balance endpoint (requires auth via bearer token)
    Route::get('/balance', [UserController::class, 'getBalance']);

    // Saved Passengers (requires auth via bearer token)
    Route::get('/saved-passengers', [\App\Http\Controllers\Api\SavedPassengerController::class, 'index']);
    Route::post('/saved-passengers', [\App\Http\Controllers\Api\SavedPassengerController::class, 'store']);
    Route::delete('/saved-passengers/{id}', [\App\Http\Controllers\Api\SavedPassengerController::class, 'destroy']);

    // =====================================================
    // PIN & PHONE VERIFICATION (SHARED)
    // =====================================================

    // PIN Management (requires auth via bearer token)
    Route::get('/pin/check', [\App\Http\Controllers\Api\PinController::class, 'checkPin']);
    Route::post('/pin/create', [\App\Http\Controllers\Api\PinController::class, 'createPin']);
    Route::post('/pin/verify', [\App\Http\Controllers\Api\PinController::class, 'verifyPin']);
    Route::post('/pin/update', [\App\Http\Controllers\Api\PinController::class, 'updatePin']);

    // Phone Verification (requires auth via bearer token)
    Route::post('/phone-verification/send-otp', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'sendOtp']);
    Route::post('/phone-verification/verify-otp', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'verifyOtp']);
    Route::post('/phone-verification/resend-otp', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'resendOtp']);
    Route::get('/phone-verification/status', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'getPhoneStatus']);

    // =====================================================
    // MITRA - RIDES MANAGEMENT
    // =====================================================

    // Rides (public - list and view)
    Route::get('/rides', [RideController::class, 'index']);
    Route::get('/rides/{id}', [RideController::class, 'show']);
    Route::get('/rides/{id}/passengers', [RideController::class, 'getRidePassengers']);

    // Rides (create - requires auth via bearer token)
    Route::post('/rides', [RideController::class, 'store']);

    // Mitra: riwayat tebengan (partner history)
    Route::get('/mitra/riwayat', [MitraHistoryController::class, 'index']);

    // =====================================================
    // MITRA - VEHICLES MANAGEMENT
    // =====================================================

    // Vehicles (requires auth via bearer token)
    Route::get('/vehicles', [VehicleController::class, 'index']);
    Route::post('/vehicles', [VehicleController::class, 'store']);
    Route::get('/vehicles/{id}', [VehicleController::class, 'show']);
    Route::put('/vehicles/{id}', [VehicleController::class, 'update']);
    Route::delete('/vehicles/{id}', [VehicleController::class, 'destroy']);

    // Vehicle approval (admin only)
    Route::post('/vehicles/{id}/approve', [VehicleController::class, 'approve']);
    Route::post('/vehicles/{id}/reject', [VehicleController::class, 'reject']);

    // Vehicle deletion approval (admin only)
    Route::post('/vehicles/{id}/approve-deletion', [VehicleController::class, 'approveDeletion']);
    Route::post('/vehicles/{id}/reject-deletion', [VehicleController::class, 'rejectDeletion']);

    // =====================================================
    // WITHDRAWAL ADMIN (requires bearer token, admin only)
    // =====================================================
    Route::get('/admin/withdrawals', [\App\Http\Controllers\Api\WithdrawalAdminController::class, 'index']);
    Route::post('/admin/withdrawals/{id}/approve', [\App\Http\Controllers\Api\WithdrawalAdminController::class, 'approve']);
    Route::post('/admin/withdrawals/{id}/complete', [\App\Http\Controllers\Api\WithdrawalAdminController::class, 'complete']);
    Route::post('/admin/withdrawals/{id}/reject', [\App\Http\Controllers\Api\WithdrawalAdminController::class, 'reject']);

    // =====================================================
    // MITRA - VERIFICATION & DOCUMENTS
    // =====================================================

    // Mitra Verification (requires auth via bearer token)
    Route::get('/mitra/verification/ktp', [\App\Http\Controllers\VerifikasiKtpController::class, 'show']);
    Route::post('/mitra/verification/ktp', [\App\Http\Controllers\VerifikasiKtpController::class, 'store']);
    Route::put('/mitra/verification/ktp', [\App\Http\Controllers\VerifikasiKtpController::class, 'update']);

    Route::get('/mitra/verification/sim', [\App\Http\Controllers\VerifikasiSimController::class, 'show']);
    Route::post('/mitra/verification/sim', [\App\Http\Controllers\VerifikasiSimController::class, 'store']);
    Route::put('/mitra/verification/sim', [\App\Http\Controllers\VerifikasiSimController::class, 'update']);

    Route::get('/mitra/verification/skck', [\App\Http\Controllers\VerifikasiSkckController::class, 'show']);
    Route::post('/mitra/verification/skck', [\App\Http\Controllers\VerifikasiSkckController::class, 'store']);
    Route::put('/mitra/verification/skck', [\App\Http\Controllers\VerifikasiSkckController::class, 'update']);

    Route::get('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'show']);
    Route::post('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'store']);
    Route::put('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'update']);

    // Link all verifications to mitra_verifikasi table
    Route::post('/mitra/verification/link', [\App\Http\Controllers\MitraVerifikasiController::class, 'linkVerifications']);

    // Get verification status
    Route::get('/mitra/verification/status', [\App\Http\Controllers\MitraVerifikasiController::class, 'getVerificationStatus']);
    // Sync individual verifications into mitra_verifikasi (development helper)
    Route::post('/mitra/verification/sync', [\App\Http\Controllers\MitraVerifikasiController::class, 'syncLinks']);

    Route::get('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'show']);
    Route::post('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'store']);
    Route::put('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'update']);

    // =====================================================
    // MITRA - WITHDRAWAL (TARIK SALDO)
    // =====================================================

    // Mitra Withdrawal (Tarik Saldo)
    Route::get('/mitra/withdrawal/balance', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'getBalanceInfo']);
    Route::post('/mitra/withdrawal/submit', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'submitRequest']);
    Route::get('/mitra/withdrawal/{id}', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'getDetail']);
    Route::get('/mitra/withdrawal/{id}/status', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'checkStatus']);
    Route::get('/mitra/withdrawal/history/list', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'getHistory']);
    Route::post('/mitra/withdrawal/{id}/reject', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'rejectWithdrawal']);
    Route::post('/mitra/pin/set', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'setPin']);
    Route::post('/mitra/pin/verify', [\App\Http\Controllers\Mitra\WithdrawalController::class, 'verifyPin']);

    // =====================================================
    // CUSTOMER - BOOKINGS & RESERVATIONS
    // =====================================================

    // Bookings: customers create a booking (reserve) before payment
    Route::post('/bookings', [\App\Http\Controllers\Api\BookingController::class, 'store']);
    // Authenticated: list current user's bookings (filter by type via ?type=semua|motor|mobil|barang|titip)
    // Note: use bearer token lookup inside controller (project uses custom ApiToken table)
    Route::get('/bookings/my', [\App\Http\Controllers\Api\BookingController::class, 'myBookings']);
    Route::get('/bookings/{id}', [\App\Http\Controllers\Api\BookingController::class, 'show']);
    // Update booking status (customer or driver can update)
    Route::put('/bookings/{id}/status', [\App\Http\Controllers\Api\BookingController::class, 'updateStatus']);
    // Cancel booking with reason
    Route::post('/bookings/{id}/cancel', [\App\Http\Controllers\Api\BookingController::class, 'cancel']);
    // Get cancellation count for user
    Route::get('/users/{userId}/cancellation-count', [\App\Http\Controllers\Api\BookingController::class, 'getCancellationCount']);

    // =====================================================
    // CUSTOMER - BOOKING TRACKING & LOCATION
    // =====================================================

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

    // =====================================================
    // CUSTOMER - RESCHEDULE BOOKINGS
    // =====================================================

    // Reschedule / change schedule endpoints
    Route::get('/bookings/{id}/available-rides', [\App\Http\Controllers\Api\RescheduleController::class, 'availableRides']);
    Route::post('/bookings/{id}/reschedule', [\App\Http\Controllers\Api\RescheduleController::class, 'store']);
    Route::get('/reschedule/{id}', [\App\Http\Controllers\Api\RescheduleController::class, 'show']);
    Route::post('/reschedule/{id}/confirm-payment', [\App\Http\Controllers\Api\RescheduleController::class, 'confirmPayment']);
    Route::put('/reschedule/{id}/approve', [\App\Http\Controllers\Api\RescheduleController::class, 'approve']);
    Route::put('/reschedule/{id}/reject', [\App\Http\Controllers\Api\RescheduleController::class, 'reject']);

    // =====================================================
    // CUSTOMER - REFUNDS
    // =====================================================

    // Refund routes
    Route::get('/refunds', [\App\Http\Controllers\Api\RefundController::class, 'index']);
    Route::get('/refunds/{id}', [\App\Http\Controllers\Api\RefundController::class, 'show']);
    Route::post('/refunds', [\App\Http\Controllers\Api\RefundController::class, 'store']);
    Route::get('/bookings/{bookingId}/refund-eligibility', [\App\Http\Controllers\Api\RefundController::class, 'checkEligibility']);

    // =====================================================
    // CUSTOMER - RATINGS & REVIEWS
    // =====================================================

    // Rating routes
    Route::post('/ratings', [\App\Http\Controllers\Api\RatingController::class, 'store']);
    Route::get('/ratings/booking/{bookingId}', [\App\Http\Controllers\Api\RatingController::class, 'show']);
    Route::get('/ratings/driver/{driverId}', [\App\Http\Controllers\Api\RatingController::class, 'getDriverRatings']);

    // Customer rating routes (mitra rates customer)
    Route::post('/customer-ratings', [\App\Http\Controllers\Api\V1\CustomerRatingController::class, 'store']);
    Route::get('/customer-ratings/booking/{bookingId}', [\App\Http\Controllers\Api\V1\CustomerRatingController::class, 'getByBooking']);
    Route::get('/customer-ratings/booking-number/{bookingNumber}', [\App\Http\Controllers\Api\V1\CustomerRatingController::class, 'getByBookingNumber']);
    Route::get('/customer-ratings/customer/{customerId}', [\App\Http\Controllers\Api\V1\CustomerRatingController::class, 'getByCustomer']);
    Route::get('/customer-ratings/mitra/{mitraId}', [\App\Http\Controllers\Api\V1\CustomerRatingController::class, 'getByMitra']);

    // =====================================================
    // CUSTOMER - REWARDS & POINTS
    // =====================================================

    // Rewards (points / merchandise)
    Route::get('/rewards', [\App\Http\Controllers\Api\RewardController::class, 'index']);
    Route::post('/rewards/{id}/redeem', [\App\Http\Controllers\Api\RewardController::class, 'redeem']);
    Route::get('/rewards/my', [\App\Http\Controllers\Api\RewardController::class, 'myRedemptions']);

    // =====================================================
    // CUSTOMER - VERIFICATION
    // =====================================================

    // Customer Verification (requires auth via bearer token)
    Route::get('/customer/verification/status', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'getStatus']);
    Route::get('/customer/verification', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'getVerification']);
    Route::post('/customer/verification/upload-face', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'uploadFacePhoto']);
    Route::post('/customer/verification/upload-ktp', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'uploadKtpPhoto']);
    Route::post('/customer/verification/upload-face-ktp', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'uploadFaceKtpPhoto']);
    Route::post('/customer/verification/submit', [\App\Http\Controllers\Api\VerifikasiCustomerController::class, 'submitVerification']);

    // =====================================================
    // CUSTOMER - TRANSACTION HISTORY
    // =====================================================

    // Customer: riwayat transaksi (transaction history) - uses custom ApiToken auth
    Route::get('/transactions/history', [TransactionHistoryController::class, 'index']);

    // =====================================================
    // PAYMENT & XENDIT
    // =====================================================

    // Payment routes
    Route::post('/payments', [PaymentController::class, 'createPayment']);
    Route::get('/payments/{id}/status', [PaymentController::class, 'checkPaymentStatus']);

    // Xendit webhook callback (no auth required)
    Route::post('/payments/webhook', [PaymentController::class, 'webhookCallback']);

    // =====================================================
    // NOTIFICATIONS & FCM
    // =====================================================

    // FCM token update from mobile app (expects bearer token)
    Route::post('/user/fcm-token', [FcmController::class, 'updateToken']);

    // Notifications (requires auth via bearer token)
    Route::get('/notifications', [\App\Http\Controllers\Api\NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [\App\Http\Controllers\Api\NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [\App\Http\Controllers\Api\NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [\App\Http\Controllers\Api\NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{id}', [\App\Http\Controllers\Api\NotificationController::class, 'destroy']);
    Route::delete('/notifications/clear-read', [\App\Http\Controllers\Api\NotificationController::class, 'clearRead']);

    // =====================================================
    // TEBENGAN TITIP BARANG (SHARED)
    // =====================================================

    // Tebengan Titip Barang routes
    Route::get('/tebengan-titip-barang', [TebenganTitipBarangController::class, 'index']);
    Route::get('/tebengan-titip-barang/{id}', [TebenganTitipBarangController::class, 'show']);
    Route::post('/tebengan-titip-barang', [TebenganTitipBarangController::class, 'store']);
    Route::put('/tebengan-titip-barang/{id}', [TebenganTitipBarangController::class, 'update']);
    Route::delete('/tebengan-titip-barang/{id}', [TebenganTitipBarangController::class, 'destroy']);
    Route::get('/tebengan-titip-barang/my/list', [TebenganTitipBarangController::class, 'myTebengan']);

    // =====================================================
    // POSMITRA - PROFILE & DASHBOARD
    // =====================================================

    Route::get('/pos-mitra/profile', [ProfileController::class, 'show']);
    Route::get('/posmitra/beranda', [BerandaController::class, 'beranda']);
    // Route::get('/posmitra/tebengan-akan-datang', [BerandaController::class, 'upcomingRides']);
    // Route::get('/posmitra/statistics', [BerandaController::class, 'statistics']);

    // =====================================================
    // ADMIN ROUTES
    // =====================================================

    // Admin routes for managing locations (requires auth:sanctum)
    Route::middleware('auth:sanctum')->prefix('admin')->group(function () {
        Route::post('/locations', [LocationController::class, 'store']);
        Route::put('/locations/{id}', [LocationController::class, 'update']);
        Route::delete('/locations/{id}', [LocationController::class, 'destroy']);
    });

    // =====================================================
    // DEVELOPMENT & TESTING ROUTES
    // =====================================================

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

    // Mitra Verification (requires auth via bearer token)
    Route::get('/mitra/verification/ktp', [\App\Http\Controllers\VerifikasiKtpController::class, 'show']);
    Route::post('/mitra/verification/ktp', [\App\Http\Controllers\VerifikasiKtpController::class, 'store']);
    Route::put('/mitra/verification/ktp', [\App\Http\Controllers\VerifikasiKtpController::class, 'update']);

    Route::get('/mitra/verification/sim', [\App\Http\Controllers\VerifikasiSimController::class, 'show']);
    Route::post('/mitra/verification/sim', [\App\Http\Controllers\VerifikasiSimController::class, 'store']);
    Route::put('/mitra/verification/sim', [\App\Http\Controllers\VerifikasiSimController::class, 'update']);

    Route::get('/mitra/verification/skck', [\App\Http\Controllers\VerifikasiSkckController::class, 'show']);
    Route::post('/mitra/verification/skck', [\App\Http\Controllers\VerifikasiSkckController::class, 'store']);
    Route::put('/mitra/verification/skck', [\App\Http\Controllers\VerifikasiSkckController::class, 'update']);

    Route::get('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'show']);
    Route::post('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'store']);
    Route::put('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'update']);

    // Link all verifications to mitra_verifikasi table
    Route::post('/mitra/verification/link', [\App\Http\Controllers\MitraVerifikasiController::class, 'linkVerifications']);

    // Get verification status
    Route::get('/mitra/verification/status', [\App\Http\Controllers\MitraVerifikasiController::class, 'getVerificationStatus']);

    Route::get('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'show']);
    Route::post('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'store']);
    Route::put('/mitra/verification/bank', [\App\Http\Controllers\VerifikasiBankController::class, 'update']);

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

    
    // Withdrawal routes
Route::prefix('v1')->group(function () {
    Route::post('posmitra/withdraw', [WithdrawController::class, 'withdraw']);
    Route::get('posmitra/withdraw/history', [WithdrawController::class, 'history']);
    Route::get('posmitra/withdraw/{id}', [WithdrawController::class, 'detail']);
});

Route::prefix('posmitra')->group(function () {
    
    // ✅ Beranda / Profile
    Route::get('/beranda', [BerandaController::class, 'beranda']);
    
    // ✅ Statistics - untuk menampilkan card statistik
    Route::get('/statistics', [BerandaController::class, 'statistics']);
    
    // ✅ Upcoming Rides - untuk tebengan akan datang
    Route::get('/upcoming-rides', [BerandaController::class, 'upcomingRides']);
    
});

Route::post('/posmitra/withdrawals/{id}/set-status', [WithdrawController::class, 'setStatus']);
// Di routes/api.php
Route::get('/posmitra/completed-rides', [BerandaController::class, 'completedRides']);