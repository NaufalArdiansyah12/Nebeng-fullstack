<?php

use Illuminate\Support\Facades\Password;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\TransactionController;

// lupa password routes
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
    Route::get('/count-by-role', [UserController::class, 'countByRole']);
    Route::get('/mitra', [UserController::class, 'getMitraUsers']);
    Route::post('/login', [UserController::class, 'login']);
    Route::get('/{id}', [UserController::class, 'getById']);
    Route::get('/profile/{id}', [UserController::class, 'profile']);
    Route::put('/profile/{id}', [UserController::class, 'updateProfile']);
    Route::put('/account/{id}', [UserController::class, 'updateAccount']);
});