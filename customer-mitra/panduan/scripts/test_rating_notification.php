<?php
/**
 * Script untuk test rating notification
 * Usage: php artisan tinker < test_rating_notification.php
 * Or run in tinker: include 'test_rating_notification.php';
 */

use App\Models\Rating;
use App\Models\User;
use App\Services\MitraNotificationService;

echo "=== Testing Rating Notification ===\n\n";

// 1. Find atau buat sample rating
echo "Step 1: Finding or creating sample rating...\n";

$driver = User::where('role', 'mitra')->first();
if (!$driver) {
    echo "ERROR: No mitra user found in database!\n";
    exit;
}
echo "Driver found: {$driver->name} (ID: {$driver->id})\n\n";

$customer = User::where('role', 'customer')->first();
if (!$customer) {
    echo "ERROR: No customer user found in database!\n";
    exit;
}
echo "Customer found: {$customer->name} (ID: {$customer->id})\n\n";

// Cari rating terakhir atau buat dummy
$rating = Rating::where('driver_id', $driver->id)->latest()->first();

if (!$rating) {
    echo "No existing rating found. Creating dummy rating...\n";
    $rating = new Rating([
        'booking_id' => 999,
        'booking_type' => 'motor',
        'user_id' => $customer->id,
        'driver_id' => $driver->id,
        'rating' => 5,
        'review' => 'Test rating untuk notifikasi - Driver sangat baik!',
    ]);
    $rating->save();
    echo "Dummy rating created with ID: {$rating->id}\n\n";
} else {
    echo "Using existing rating ID: {$rating->id}\n\n";
}

// Load relationships
$rating->load(['user', 'driver']);

// 2. Send notification
echo "Step 2: Sending notification to driver...\n";
try {
    MitraNotificationService::sendRatingReceivedNotification($rating, $driver);
    echo "✓ Notification sent successfully!\n\n";
} catch (Exception $e) {
    echo "✗ Error sending notification: " . $e->getMessage() . "\n\n";
    exit;
}

// 3. Check notification in database
echo "Step 3: Checking notifications table...\n";
$notification = \App\Models\Notification::where('user_id', $driver->id)
    ->where('type', 'rating_received')
    ->latest()
    ->first();

if ($notification) {
    echo "✓ Notification found in database!\n";
    echo "  Title: {$notification->title}\n";
    echo "  Body: {$notification->message}\n";
    echo "  Icon: {$notification->icon}\n";
    echo "  Is Read: " . ($notification->is_read ? 'Yes' : 'No') . "\n";
    echo "  Created: {$notification->created_at}\n\n";
} else {
    echo "✗ Notification NOT found in database!\n\n";
}

// 4. Check FCM token
echo "Step 4: Checking FCM token...\n";
if ($driver->fcm_token) {
    echo "✓ Driver has FCM token: " . substr($driver->fcm_token, 0, 20) . "...\n";
    echo "  Push notification should have been sent.\n\n";
} else {
    echo "⚠ Driver does NOT have FCM token\n";
    echo "  Only in-app notification saved to database.\n\n";
}

// 5. Summary
echo "=== Test Summary ===\n";
echo "Driver ID: {$driver->id}\n";
echo "Driver Name: {$driver->name}\n";
echo "Rating ID: {$rating->id}\n";
echo "Rating Value: {$rating->rating} stars\n";
echo "Customer: {$customer->name}\n";
echo "Review: {$rating->review}\n\n";

echo "To verify on mobile app:\n";
echo "1. Login as mitra user: {$driver->email}\n";
echo "2. Go to Notifications page\n";
echo "3. Look for rating notification from {$customer->name}\n\n";

echo "=== Test Complete ===\n";
