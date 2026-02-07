<?php
require __DIR__ . '/../vendor/autoload.php';
$app = require __DIR__ . '/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$userId = $argv[1] ?? 1;
$token = $argv[2] ?? 'cjGl0AXiTCS9A8dfia8-_a:APA91bF38T-irf7iENe1JRG2okYRGgOPCohG_ECzI5RTkIkxr2QnccxsyqqvIXvga5FhUxB0VWeW_J2RuT5brexm3DiLX5hhWvRyXVqF4pLJpqttxhFa1SM';

$user = App\Models\User::find($userId);
if (!$user) {
    echo "User not found\n";
    exit(1);
}
$user->fcm_token = $token;
$user->save();

echo "Updated user {$userId} fcm_token.\n";
