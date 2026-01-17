<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();
$payment = App\Models\Payment::orderBy('id', 'desc')->first();
if (!$payment) {
    echo "NO_PAYMENT\n";
    exit(0);
}
$user = $payment->user;
echo "PAYMENT_ID=" . $payment->id . "\n";
echo "EXTERNAL_ID=" . $payment->external_id . "\n";
echo "USER_ID=" . ($payment->user_id ?? 'NULL') . "\n";
echo "USER_FCM=" . (($user && isset($user->fcm_token)) ? $user->fcm_token : 'NULL') . "\n";
