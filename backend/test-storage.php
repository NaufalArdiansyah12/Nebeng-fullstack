<?php

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

// Test storage
use Illuminate\Support\Facades\Storage;

echo "Testing storage write...\n";

// Create a test file
$content = "Test content - " . date('Y-m-d H:i:s');
$filename = 'verifikasi/wajah/test_' . time() . '.txt';

try {
    Storage::disk('public')->put($filename, $content);
    echo "✓ File created: $filename\n";
    
    // Check if file exists
    $path = storage_path('app/public/' . $filename);
    if (file_exists($path)) {
        echo "✓ File exists at: $path\n";
        echo "✓ File content: " . file_get_contents($path) . "\n";
    } else {
        echo "✗ File does not exist at: $path\n";
    }
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "\n";
}
