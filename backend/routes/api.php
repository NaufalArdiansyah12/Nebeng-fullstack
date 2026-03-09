<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Hash;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\FcmController;
use App\Http\Controllers\Api\FcmTestController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Mitra\RideController;
use App\Http\Controllers\Mitra\VehicleController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PaymentTestController;
// App\Http\Controllers\TebenganTitipBarangController removed (deprecated)
// use App\Http\Controllers\TebenganTitipBarangController;
use App\Http\Controllers\Mitra\MitraHistoryController;
use App\Http\Controllers\Customer\TransactionHistoryController;
use App\Http\Controllers\Finance\DashboardController;
use App\Http\Controllers\Finance\BookingController;
use App\Http\Controllers\Finance\UserController as FinanceUserController;
use App\Http\Controllers\Finance\TransactionController;
use App\Http\Controllers\Finance\RefundController;
use App\Http\Controllers\Finance\WithdrawalController;
use App\Http\Controllers\Finance\PricingController;
use App\Http\Controllers\Finance\SettingsController;
// App\Http\Controllers\Finance\PricePerKgController removed (deprecated)
// use App\Http\Controllers\Finance\PricePerKgController;
use App\Http\Controllers\PosMitra\ProfileController;
use App\Http\Controllers\PosMitra\BerandaController;
use App\Http\Controllers\PosMitra\QrController;

// Customer Controllers
use App\Http\Controllers\Customer\BookingController as CustomerBookingController;
use App\Http\Controllers\Customer\BookingLocationController;
use App\Http\Controllers\Customer\BookingTrackingController;
use App\Http\Controllers\Customer\SavedPassengerController;
use App\Http\Controllers\Customer\RatingController;
use App\Http\Controllers\Customer\RescheduleController;
use App\Http\Controllers\Customer\RewardController;
use App\Http\Controllers\Customer\VerifikasiCustomerController;
use App\Http\Controllers\Customer\NotificationController;
use App\Http\Controllers\Customer\BookingMotorController;
use App\Http\Controllers\Customer\BookingMobilController;
use App\Http\Controllers\Customer\BookingBarangController;
use App\Http\Controllers\Customer\BookingTitipBarangController;
use App\Http\Controllers\Customer\BookingMobilLocationController;
use App\Http\Controllers\Customer\BookingMobilTrackingController;
use App\Http\Controllers\Customer\BookingBarangLocationController;
use App\Http\Controllers\Customer\BookingBarangTrackingController;
use App\Http\Controllers\Customer\BookingTitipBarangLocationController;
use App\Http\Controllers\Customer\BookingTitipBarangTrackingController;
use App\Http\Controllers\Customer\RefundController as CustomerRefundController;
use App\Http\Controllers\Customer\PointController;
use App\Http\Controllers\Api\BannerController;

// Admin Controllers
use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\DashboardController as AdminDashboardController;
use App\Http\Controllers\Admin\MitraController as AdminMitraController;
use App\Http\Controllers\Admin\CustomerController as AdminCustomerController;
use App\Http\Controllers\Admin\PesananController as AdminPesananController;
use App\Http\Controllers\Admin\LaporanController as AdminLaporanController;
use App\Http\Controllers\Admin\RefundController as AdminRefundController;
use App\Http\Controllers\Admin\UserManagementController as AdminUserManagementController;


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

    // Weight category options endpoint
    Route::get('/weight-categories', [App\Http\Controllers\Api\WeightCategoryController::class, 'index']);

    // Pricing Config endpoints (new simplified API)
    Route::get('/finance/pricing-config', [App\Http\Controllers\Finance\PricingConfigController::class, 'index']);
    Route::get('/finance/pricing-config/{slug}', [App\Http\Controllers\Finance\PricingConfigController::class, 'show']);
    Route::put('/finance/pricing-config/{slug}', [App\Http\Controllers\Finance\PricingConfigController::class, 'update']);
    Route::get('/finance/weight-categories', [App\Http\Controllers\Finance\PricingConfigController::class, 'weightCategories']);

    // Pricing endpoints (finance) - keep for backward compatibility
    Route::get('/finance/pricing-profiles', [PricingController::class, 'index']);
    Route::get('/finance/pricing-profiles/{id}', [PricingController::class, 'show']);
    Route::post('/finance/pricing-profiles', [PricingController::class, 'store']);
    Route::put('/finance/pricing-profiles/{id}', [PricingController::class, 'update']);
    Route::delete('/finance/pricing-profiles/{id}', [PricingController::class, 'destroy']);

    // Finance settings (fees)
    Route::get('/finance/settings/fees', [SettingsController::class, 'getFees']);
    Route::put('/finance/settings/fees', [SettingsController::class, 'updateFees']);

    // Calculate price (public helper)
    Route::get('/finance/price/calculate', [PricingController::class, 'calculate']);

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
    // CHAT & NOTIFICATIONS
    // =====================================================

    // Chat notification endpoint
    Route::post('/chat/notify', [\App\Http\Controllers\Api\ChatController::class, 'notifyNewMessage']);
    Route::get('/chat/notify/test', [\App\Http\Controllers\Api\ChatController::class, 'testNotification']);

    // =====================================================
    // AUTHENTICATION & AUTHORIZATION
    // =====================================================

    // Auth
    Route::post('/auth/register', [\App\Http\Controllers\Api\AuthController::class, 'register']);
    Route::post('/auth/login', [\App\Http\Controllers\Api\AuthController::class, 'login']);
    Route::post('/auth/login/posmitra', [\App\Http\Controllers\Api\AuthController::class, 'loginPosMitra']);
    Route::post('/auth/google', [\App\Http\Controllers\Api\GoogleAuthController::class, 'handleGoogleAuth']);
    Route::post('/auth/logout', [\App\Http\Controllers\Api\AuthController::class, 'logout'])->middleware('check.user.status');
    Route::post('/auth/change-password', [\App\Http\Controllers\Api\AuthController::class, 'changePassword'])->middleware('check.user.status');
    Route::get('/auth/me', [\App\Http\Controllers\Api\AuthController::class, 'me'])->middleware('check.user.status');
    // Update profile (authenticated via Bearer token)
    Route::post('/auth/update-profile', [\App\Http\Controllers\Api\AuthController::class, 'updateProfile'])->middleware('check.user.status');

    // =====================================================
    // USER BALANCE & SAVED DATA (Protected with user status check)
    // =====================================================

    // Balance endpoint (requires auth via bearer token)
    Route::get('/balance', [UserController::class, 'getBalance'])->middleware('check.user.status');

    // Saved Passengers (requires auth via bearer token)
    Route::get('/saved-passengers', [SavedPassengerController::class, 'index'])->middleware('check.user.status');
    Route::post('/saved-passengers', [SavedPassengerController::class, 'store'])->middleware('check.user.status');
    Route::delete('/saved-passengers/{id}', [SavedPassengerController::class, 'destroy'])->middleware('check.user.status');

    // =====================================================
    // PIN & PHONE VERIFICATION (SHARED)
    // =====================================================

    // PIN Management (requires auth via bearer token)
    Route::get('/pin/check', [\App\Http\Controllers\Api\PinController::class, 'checkPin'])->middleware('check.user.status');
    Route::post('/pin/create', [\App\Http\Controllers\Api\PinController::class, 'createPin'])->middleware('check.user.status');
    Route::post('/pin/verify', [\App\Http\Controllers\Api\PinController::class, 'verifyPin'])->middleware('check.user.status');
    Route::post('/pin/update', [\App\Http\Controllers\Api\PinController::class, 'updatePin'])->middleware('check.user.status');

    // Phone Verification (requires auth via bearer token)
    Route::post('/phone-verification/send-otp', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'sendOtp'])->middleware('check.user.status');
    Route::post('/phone-verification/verify-otp', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'verifyOtp'])->middleware('check.user.status');
    Route::post('/phone-verification/resend-otp', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'resendOtp'])->middleware('check.user.status');
    Route::get('/phone-verification/status', [\App\Http\Controllers\Api\PhoneVerificationController::class, 'getPhoneStatus'])->middleware('check.user.status');

    // =====================================================
    // MITRA - RIDES MANAGEMENT
    // =====================================================

    // Rides (public - list and view)
    Route::get('/rides', [RideController::class, 'index']);
    Route::get('/rides/{id}', [RideController::class, 'show']);
    Route::get('/rides/{id}/passengers', [RideController::class, 'getRidePassengers']);

    // Rides (create - requires auth via bearer token)
    Route::post('/rides', [RideController::class, 'store'])->middleware('check.user.status');
    
    // Rides (cancel - requires auth via bearer token)
    Route::post('/rides/{id}/cancel', [RideController::class, 'cancelRide'])->middleware('check.user.status');
    
    // Get mitra cancellation count for current month
    Route::get('/mitra/{mitraId}/cancellation-count', [RideController::class, 'getMitraCancellationCount'])->middleware('check.user.status');

    // Mitra: riwayat tebengan (partner history)
    Route::get('/mitra/riwayat', [MitraHistoryController::class, 'index'])->middleware('check.user.status');
    
    // Mitra: check location bypass setting
    Route::get('/mitra/location/{locationId}/bypass', [\App\Http\Controllers\Api\V1\Mitra\LocationBypassController::class, 'checkBypass'])->middleware(['auth.api.token', 'check.user.status']);
    
    // Mitra: complete trip by driver (bypass QR scan)
    Route::post('/booking/{bookingType}/{bookingId}/complete-by-driver', [\App\Http\Controllers\Api\V1\Mitra\CompleteTripController::class, 'completeByDriver'])->middleware(['auth.api.token', 'check.user.status']);

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
    Route::post('/bookings', [CustomerBookingController::class, 'store']);
    // Authenticated: list current user's bookings (filter by type via ?type=semua|motor|mobil|barang|titip)
    // Note: use bearer token lookup inside controller (project uses custom ApiToken table)
    Route::get('/bookings/my', [CustomerBookingController::class, 'myBookings']);
    Route::get('/bookings/{id}', [CustomerBookingController::class, 'show']);
    // Update booking status (customer or driver can update)
    Route::put('/bookings/{id}/status', [CustomerBookingController::class, 'updateStatus']);
    // Cancel booking with reason
    Route::post('/bookings/{id}/cancel', [CustomerBookingController::class, 'cancel']);
    // Get cancellation count for user
    Route::get('/users/{userId}/cancellation-count', [CustomerBookingController::class, 'getCancellationCount']);

    // =====================================================
    // CUSTOMER - BOOKING TRACKING & LOCATION
    // =====================================================

    // Get comprehensive tracking info
    Route::get('/bookings/{id}/tracking', [BookingTrackingController::class, 'show']);
    // Driver actions for trip
    Route::post('/bookings/{id}/start-trip', [BookingTrackingController::class, 'startTrip']);
    Route::post('/bookings/{id}/complete-trip', [BookingTrackingController::class, 'completeTrip']);
    // Accept location updates from drivers for a booking (expects bearer token)
    Route::post('/bookings/{id}/location', [\App\Http\Controllers\Customer\BookingLocationController::class, 'store']);
    // Get latest location for a booking (requires bearer token). Supports If-Modified-Since and If-None-Match.
    Route::get('/bookings/{id}/location', [\App\Http\Controllers\Customer\BookingLocationController::class, 'show']);

    // Booking Mobil Query & Tracking & Location
    Route::get('/booking-mobil', [BookingMobilController::class, 'index']);
    Route::get('/booking-mobil/{id}/tracking', [BookingMobilTrackingController::class, 'show']);
    Route::post('/booking-mobil/{id}/start-trip', [BookingMobilTrackingController::class, 'startTrip']);
    Route::post('/booking-mobil/{id}/complete-trip', [BookingMobilTrackingController::class, 'completeTrip']);
    Route::post('/booking-mobil/{id}/location', [BookingMobilLocationController::class, 'store']);
    Route::get('/booking-mobil/{id}/location', [BookingMobilLocationController::class, 'show']);

    // Booking Barang Tracking & Location
    Route::get('/booking-barang', [BookingBarangController::class, 'index']);
    Route::get('/booking-barang/{id}/tracking', [BookingBarangTrackingController::class, 'show']);
    Route::post('/booking-barang/{id}/start-trip', [BookingBarangTrackingController::class, 'startTrip']);
    Route::post('/booking-barang/{id}/complete-trip', [BookingBarangTrackingController::class, 'completeTrip']);
    Route::post('/booking-barang/{id}/location', [BookingBarangLocationController::class, 'store']);
    Route::get('/booking-barang/{id}/location', [BookingBarangLocationController::class, 'show']);

    // Booking Titip Barang Tracking & Location
    Route::get('/booking-titip-barang', [BookingTitipBarangController::class, 'index']);
    Route::get('/booking-titip-barang/{id}/tracking', [BookingTitipBarangTrackingController::class, 'show']);
    Route::post('/booking-titip-barang/{id}/start-trip', [BookingTitipBarangTrackingController::class, 'startTrip']);
    Route::post('/booking-titip-barang/{id}/complete-trip', [BookingTitipBarangTrackingController::class, 'completeTrip']);
    Route::post('/booking-titip-barang/{id}/location', [BookingTitipBarangLocationController::class, 'store']);
    Route::get('/booking-titip-barang/{id}/location', [BookingTitipBarangLocationController::class, 'show']);

    // Restore legacy Tebengan Titip Barang endpoints (temporary compatibility)
    Route::post('/tebengan-titip-barang', [\App\Http\Controllers\TebenganTitipBarangController::class, 'store']);
    Route::get('/tebengan-titip-barang', [\App\Http\Controllers\TebenganTitipBarangController::class, 'index']);
    Route::get('/tebengan-titip-barang/{id}', [\App\Http\Controllers\TebenganTitipBarangController::class, 'show']);

    // =====================================================
    // CUSTOMER - RESCHEDULE BOOKINGS
    // =====================================================

    // Reschedule / change schedule endpoints
    Route::get('/bookings/{id}/available-rides', [RescheduleController::class, 'availableRides']);
    Route::post('/bookings/{id}/reschedule', [RescheduleController::class, 'store']);
    Route::get('/reschedule/{id}', [RescheduleController::class, 'show']);
    Route::post('/reschedule/{id}/confirm-payment', [RescheduleController::class, 'confirmPayment']);
    Route::put('/reschedule/{id}/approve', [RescheduleController::class, 'approve']);
    Route::put('/reschedule/{id}/reject', [RescheduleController::class, 'reject']);

    // =====================================================
    // CUSTOMER - REFUNDS
    // =====================================================

    // Refund routes
    Route::get('/refunds', [CustomerRefundController::class, 'index']);
    Route::get('/refunds/{id}', [CustomerRefundController::class, 'show']);
    Route::post('/refunds', [CustomerRefundController::class, 'store']);
    Route::get('/bookings/{bookingId}/refund-eligibility', [CustomerRefundController::class, 'checkEligibility']);

    // =====================================================
    // CUSTOMER - REWARD POINTS
    // =====================================================

    // Point routes
    Route::get('/points', [PointController::class, 'index']);
    Route::get('/points/values', [PointController::class, 'getPointValues']);

    // Banners (public)
    Route::get('/banners', [BannerController::class, 'index']);
    Route::post('/banners', [BannerController::class, 'store']);
    Route::put('/banners/{id}', [BannerController::class, 'update']);
    Route::delete('/banners/{id}', [BannerController::class, 'destroy']);


    // =====================================================
    // CUSTOMER - RATINGS & REVIEWS
    // =====================================================

    // Rating routes
    Route::post('/ratings', [RatingController::class, 'store']);
    Route::get('/ratings/booking/{bookingId}', [RatingController::class, 'show']);
    Route::get('/ratings/driver/{driverId}', [RatingController::class, 'getDriverRatings']);

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
    Route::get('/rewards', [RewardController::class, 'index']);
    Route::post('/rewards/{id}/redeem', [RewardController::class, 'redeem']);
    Route::get('/rewards/my', [RewardController::class, 'myRedemptions']);

    // =====================================================
    // CUSTOMER - VERIFICATION
    // =====================================================

    // Customer Verification (requires auth via bearer token)
    Route::get('/customer/verification/status', [VerifikasiCustomerController::class, 'getStatus']);
    Route::get('/customer/verification', [VerifikasiCustomerController::class, 'getVerification']);
    Route::post('/customer/verification/upload-face', [VerifikasiCustomerController::class, 'uploadFacePhoto']);
    Route::post('/customer/verification/upload-ktp', [VerifikasiCustomerController::class, 'uploadKtpPhoto']);
    Route::post('/customer/verification/upload-face-ktp', [VerifikasiCustomerController::class, 'uploadFaceKtpPhoto']);
    Route::post('/customer/verification/submit', [VerifikasiCustomerController::class, 'submitVerification']);

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
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    Route::delete('/notifications/clear-read', [NotificationController::class, 'clearRead']);

    // =====================================================
    // TEBENGAN TITIP BARANG (SHARED) - REMOVED
    // =====================================================
    // Routes for 'tebengan-titip-barang' have been removed and the
    // implementation moved to backend/deprecated/removed_price_system.
    // If you need to restore: see backend/deprecated/removed_price_system/TebenganTitipBarangController.php

    // =====================================================
    // POSMITRA - PROFILE & DASHBOARD
    // =====================================================

    Route::get('/pos-mitra/profile', [ProfileController::class, 'show']);
    Route::get('/posmitra/beranda', [BerandaController::class, 'beranda']);
    Route::get('/posmitra/tebengan-akan-datang', [BerandaController::class, 'upcomingRides']);
    Route::get('/posmitra/statistics', [BerandaController::class, 'statistics']);

    // =====================================================
    // POSMITRA - QR CODE SCANNING
    // =====================================================

    Route::post('/posmitra/qr/verify', [QrController::class, 'verifyQRCode']);
    Route::post('/posmitra/rides/complete', [QrController::class, 'completeRide']);

    // =====================================================
    // ADMIN ROUTES
    // =====================================================

    // Admin routes for managing locations (requires auth:sanctum)
    Route::middleware('auth:sanctum')->prefix('admin')->group(function () {
        Route::post('/locations', [LocationController::class, 'store']);
        Route::put('/locations/{id}', [LocationController::class, 'update']);
        Route::delete('/locations/{id}', [LocationController::class, 'destroy']);
        
        // User management - blocking
        Route::post('/users/{userId}/block', [AdminUserManagementController::class, 'blockUser']);
        Route::post('/users/{userId}/unblock', [AdminUserManagementController::class, 'unblockUser']);
        Route::get('/users/{userId}/status', [AdminUserManagementController::class, 'getUserStatus']);
        Route::get('/users/blocked', [AdminUserManagementController::class, 'getBlockedUsers']);
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


    // Tebengan Titip Barang routes removed (see deprecated/removed_price_system)

    // Mitra: riwayat tebengan (partner history)
    Route::get('/mitra/riwayat', [MitraHistoryController::class, 'index']);

    // Customer: riwayat transaksi (transaction history) - uses custom ApiToken auth
    Route::get('/transactions/history', [TransactionHistoryController::class, 'index']);

    // Admin routes for managing locations (requires auth:sanctum)
    Route::middleware('auth:sanctum')->prefix('admin')->group(function () {
        Route::post('/locations', [LocationController::class, 'store']);
        Route::put('/locations/{id}', [LocationController::class, 'update']);
        Route::delete('/locations/{id}', [LocationController::class, 'destroy']);
    });
});

// =====================================================
// Finance Dashboard Routes (available under /api/v1/finance)
// =====================================================
Route::prefix('v1/finance')->group(function () {
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
    Route::get('/bookings/transactions/{id}', [BookingController::class, 'getTransactionDetail']);

    // Transaction routes
    Route::get('/transactions/{id}', [TransactionController::class, 'getById']);

    // Notification routes
    Route::get('/notifications', [App\Http\Controllers\Finance\NotificationController::class, 'index']);
    Route::put('/notifications/{id}/read', [App\Http\Controllers\Finance\NotificationController::class, 'markAsRead']);
    Route::post('/notifications/read-all', [App\Http\Controllers\Finance\NotificationController::class, 'markAllAsRead']);

    // User routes
    Route::prefix('users')->group(function () {
        Route::get('/count-by-role', [FinanceUserController::class, 'countByRole']);
        Route::get('/mitra', [FinanceUserController::class, 'getMitraUsers']);
        Route::get('/mitra/{id}', [FinanceUserController::class, 'getMitraDetail']);
        Route::get('/pos-mitra', [FinanceUserController::class, 'getPosMitraUsers']);
        Route::get('/pos-mitra/{id}', [FinanceUserController::class, 'getPosMitraDetail']);
        Route::post('/login', [FinanceUserController::class, 'login']);
        Route::post('/forgot-password', [FinanceUserController::class, 'forgotPassword']);
        Route::post('/verify-otp', [FinanceUserController::class, 'verifyOtp']);
        Route::post('/reset-password', [FinanceUserController::class, 'resetPassword']);
        Route::get('/profile/{id}', [FinanceUserController::class, 'profile']);
        Route::put('/profile/{id}', [FinanceUserController::class, 'updateProfile']);
        Route::put('/account/{id}', [FinanceUserController::class, 'updateAccount']);
        Route::post('/profile/{id}/upload-image', [FinanceUserController::class, 'uploadProfileImage']);
        Route::get('/{id}', [FinanceUserController::class, 'getById']);
    });

    // Refund routes
    Route::prefix('refunds')->group(function () {
        Route::get('/', [RefundController::class, 'index']);
        Route::get('/statistics', [RefundController::class, 'statistics']);
        Route::get('/{id}', [RefundController::class, 'show']);
        Route::post('/{id}/approve', [RefundController::class, 'approve']);
        Route::post('/{id}/reject', [RefundController::class, 'reject']);
        Route::post('/{id}/process', [RefundController::class, 'process']);
        Route::post('/{id}/complete', [RefundController::class, 'complete']);
    });

    // Withdrawal routes
    Route::prefix('withdrawals')->group(function () {
        Route::get('/', [WithdrawalController::class, 'index']);
        Route::get('/{id}', [WithdrawalController::class, 'show']);
        Route::post('/{id}/approve', [WithdrawalController::class, 'approve']);
        Route::post('/{id}/reject', [WithdrawalController::class, 'reject']);
        Route::post('/{id}/process', [WithdrawalController::class, 'process']);
        Route::post('/{id}/complete', [WithdrawalController::class, 'complete']);
    });

    // Price Per Kg routes removed (deprecated)
    // The price-per-kg implementation has been removed from active routes.
    // Implementation moved to backend/deprecated/removed_price_system for archival.
});

// =====================================================
// SUPERADMIN PANEL ROUTES
// =====================================================
Route::prefix('superadmin')->group(function () {
    
    // Location QR Bypass Settings
    Route::prefix('location-qr-bypass')->group(function () {
        Route::get('/', [\App\Http\Controllers\Api\V1\SuperAdmin\LocationQRBypassController::class, 'index']);
        Route::put('/{locationId}', [\App\Http\Controllers\Api\V1\SuperAdmin\LocationQRBypassController::class, 'update']);
    });
    
    // Customer Management (menggunakan AdminCustomerController)
    Route::prefix('customers')->group(function () {
        Route::get('/', [AdminCustomerController::class, 'index']);
        Route::get('/pending-verification', [AdminCustomerController::class, 'pendingVerification']);
        Route::get('/blocked', [AdminCustomerController::class, 'blocked']);
        Route::get('/{id}', [AdminCustomerController::class, 'show']);
        Route::post('/{id}/verify', [AdminCustomerController::class, 'verify']);
        Route::post('/{id}/block', [AdminCustomerController::class, 'block']);
        Route::post('/{id}/unblock', [AdminCustomerController::class, 'unblock']);
    });
    
    // Mitra Management
    Route::prefix('mitra')->group(function () {
        Route::get('/', [AdminMitraController::class, 'index']);
        Route::get('/{id}', [AdminMitraController::class, 'show']);
        Route::post('/{id}/verify', [AdminMitraController::class, 'verify']);
        Route::post('/{id}/reject', [AdminMitraController::class, 'reject']);
        Route::post('/{id}/block', [AdminMitraController::class, 'block']);
        Route::post('/{id}/unblock', [AdminMitraController::class, 'unblock']);
        Route::get('/{id}/vehicles', [AdminMitraController::class, 'vehicles']);
    });
});

// =====================================================
// ADMIN PANEL ROUTES
// =====================================================
Route::prefix('admin')->group(function () {
    
    // Auth routes (public)
    Route::post('/auth/login', [AdminAuthController::class, 'login']);
    
    // Protected admin routes (require admin.auth middleware)
    Route::middleware('admin.auth')->group(function () {
        
        // Auth
        Route::post('/auth/logout', [AdminAuthController::class, 'logout']);
        Route::get('/auth/verify', [AdminAuthController::class, 'verify']);
        Route::get('/auth/profile', [AdminAuthController::class, 'profile']);
        Route::put('/auth/profile', [AdminAuthController::class, 'updateProfile']);
        
        // Dashboard
        Route::get('/dashboard', [AdminDashboardController::class, 'index']);
        
        // Mitra Management
        Route::prefix('mitra')->group(function () {
            Route::get('/', [AdminMitraController::class, 'index']);
            Route::get('/{id}', [AdminMitraController::class, 'show']);
            Route::post('/{id}/verify', [AdminMitraController::class, 'verify']);
            Route::post('/{id}/reject', [AdminMitraController::class, 'reject']);
            Route::post('/{id}/block', [AdminMitraController::class, 'block']);
            Route::post('/{id}/unblock', [AdminMitraController::class, 'unblock']);
            Route::get('/{id}/vehicles', [AdminMitraController::class, 'vehicles']);
        });
        
        // Vehicles Management
        Route::prefix('vehicles')->group(function () {
            Route::get('/', [AdminMitraController::class, 'allVehicles']);
            Route::get('/{id}', [AdminMitraController::class, 'vehicleDetail']);
        });
        
        // Customer Management
        Route::prefix('customers')->group(function () {
            Route::get('/', [AdminCustomerController::class, 'index']);
            Route::get('/pending-verification', [AdminCustomerController::class, 'pendingVerification']);
            Route::get('/blocked', [AdminCustomerController::class, 'blocked']);
            Route::get('/{id}', [AdminCustomerController::class, 'show']);
            Route::post('/{id}/verify', [AdminCustomerController::class, 'verify']);
            Route::post('/{id}/block', [AdminCustomerController::class, 'block']);
            Route::post('/{id}/unblock', [AdminCustomerController::class, 'unblock']);
        });
        
        // Pesanan/Booking Management
        Route::prefix('pesanan')->group(function () {
            Route::get('/', [AdminPesananController::class, 'index']);
            Route::get('/statistics', [AdminPesananController::class, 'statistics']);
            Route::get('/{id}', [AdminPesananController::class, 'show']);
        });
        
        // Laporan Management
        Route::prefix('laporan')->group(function () {
            Route::get('/', [AdminLaporanController::class, 'index']);
            Route::get('/statistics', [AdminLaporanController::class, 'statistics']);
            Route::get('/{id}', [AdminLaporanController::class, 'show']);
            Route::post('/', [AdminLaporanController::class, 'store']);
            Route::put('/{id}/status', [AdminLaporanController::class, 'updateStatus']);
            Route::post('/{id}/resolve', [AdminLaporanController::class, 'resolve']);
        });
        
        // Refund Management
        Route::prefix('refund')->group(function () {
            Route::get('/', [AdminRefundController::class, 'index']);
            Route::get('/statistics', [AdminRefundController::class, 'statistics']);
            Route::get('/{id}', [AdminRefundController::class, 'show']);
            Route::post('/{id}/approve', [AdminRefundController::class, 'approve']);
            Route::post('/{id}/reject', [AdminRefundController::class, 'reject']);
            Route::put('/{id}/status', [AdminRefundController::class, 'updateStatus']);
        });
    });
});
