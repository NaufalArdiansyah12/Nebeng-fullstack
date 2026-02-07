<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Http;
use Carbon\Carbon;

class CleanupExpiredConversations extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'conversations:cleanup';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Delete conversations that are 24 hours past booking completion';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        try {
            $this->info('🔍 Starting cleanup of expired conversations...');

            $serviceAccountPath = env('FIREBASE_CREDENTIALS') ?? env('FCM_SERVICE_ACCOUNT');
            
            if (empty($serviceAccountPath) || !file_exists($serviceAccountPath)) {
                $this->error('❌ Firebase credentials not found at: ' . ($serviceAccountPath ?? 'null'));
                Log::error('Firebase credentials not configured for conversation cleanup');
                return 1;
            }

            $serviceAccount = json_decode(file_get_contents($serviceAccountPath), true);
            $projectId = $serviceAccount['project_id'] ?? null;
            
            if (!$projectId) {
                $this->error('❌ Firebase project_id not found in service account');
                return 1;
            }

            // Get OAuth access token
            $accessToken = $this->getAccessToken($serviceAccount);
            if (!$accessToken) {
                $this->error('❌ Failed to get Firebase access token');
                return 1;
            }

            $this->info("🔑 Got access token, scanning conversations...");
            
            // Get all conversations using Firestore REST API
            $listUrl = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/conversations";
            $response = Http::withToken($accessToken)->get($listUrl);
            
            if (!$response->successful()) {
                $this->error('❌ Failed to fetch conversations: ' . $response->body());
                return 1;
            }

            $conversations = $response->json()['documents'] ?? [];
            $deletedCount = 0;
            $now = Carbon::now();

            foreach ($conversations as $conversation) {
                $fields = $conversation['fields'] ?? [];
                $conversationName = $conversation['name'] ?? '';
                
                // Extract conversation ID from name (last part after /)
                $conversationId = basename($conversationName);
                
                // Check if has booking_completed_at
                if (isset($fields['booking_completed_at']['timestampValue'])) {
                    $completedAtStr = $fields['booking_completed_at']['timestampValue'];
                    $completedAt = Carbon::parse($completedAtStr);
                    $hoursSinceCompletion = $now->diffInHours($completedAt);
                    
                    // Delete if more than 24 hours
                    if ($hoursSinceCompletion >= 24) {
                        // Delete messages subcollection first
                        $messagesUrl = "{$listUrl}/{$conversationId}/messages";
                        $messagesResponse = Http::withToken($accessToken)->get($messagesUrl);
                        
                        if ($messagesResponse->successful()) {
                            $messages = $messagesResponse->json()['documents'] ?? [];
                            foreach ($messages as $message) {
                                $messageName = $message['name'] ?? '';
                                if ($messageName) {
                                    Http::withToken($accessToken)->delete("https://firestore.googleapis.com/v1/{$messageName}");
                                }
                            }
                        }
                        
                        // Delete conversation document
                        $deleteResponse = Http::withToken($accessToken)->delete("https://firestore.googleapis.com/v1/{$conversationName}");
                        
                        if ($deleteResponse->successful()) {
                            $deletedCount++;
                            $this->info("✅ Deleted conversation {$conversationId} (completed {$hoursSinceCompletion}h ago)");
                            Log::info("Deleted expired conversation", [
                                'conversation_id' => $conversationId,
                                'completed_at' => $completedAt->toDateTimeString(),
                                'hours_since_completion' => $hoursSinceCompletion
                            ]);
                        }
                    } else {
                        $this->line("⏳ Conversation {$conversationId} expires in " . (24 - $hoursSinceCompletion) . " hours");
                    }
                }
            }

            $this->info("🎉 Cleanup completed! Deleted {$deletedCount} expired conversation(s).");
            Log::info("Conversation cleanup completed", ['deleted_count' => $deletedCount]);
            
            return 0;
        } catch (\Exception $e) {
            $this->error("❌ Error during cleanup: " . $e->getMessage());
            Log::error("Conversation cleanup failed", [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString()
            ]);
            return 1;
        }
    }

    /**
     * Get OAuth2 access token using JWT
     */
    private function getAccessToken(array $serviceAccount): ?string
    {
        $now = time();
        $expiry = $now + 3600;

        // Create JWT header
        $header = base64_encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        
        // Create JWT claims
        $claims = base64_encode(json_encode([
            'iss' => $serviceAccount['client_email'],
            'scope' => 'https://www.googleapis.com/auth/datastore',
            'aud' => 'https://oauth2.googleapis.com/token',
            'exp' => $expiry,
            'iat' => $now,
        ]));

        // Create signature
        $signatureInput = $header . '.' . $claims;
        $privateKey = openssl_pkey_get_private($serviceAccount['private_key']);
        openssl_sign($signatureInput, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        $signatureEncoded = rtrim(strtr(base64_encode($signature), '+/', '-_'), '=');
        
        $jwt = $signatureInput . '.' . $signatureEncoded;

        // Exchange JWT for access token
        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        if ($response->successful()) {
            return $response->json()['access_token'] ?? null;
        }

        return null;
    }
}
