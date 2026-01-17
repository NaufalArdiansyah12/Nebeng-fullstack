<?php

use Illuminate\Support\Facades\Route;
Route::get('/', function () {
    return view('welcome');
});

// Ensure API routes are available but executed with the `api` middleware
// so they are not subject to web CSRF protection.
if (file_exists(__DIR__ . '/api.php')) {
    Route::middleware('api')->group(function () {
        require __DIR__ . '/api.php';
    });
}
