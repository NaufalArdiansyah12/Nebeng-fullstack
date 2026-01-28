<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Kreait\Firebase\Factory;

class FirebaseChatService
{
    protected $projectId = 'nebeng1';
    protected $accessToken;

    public function __construct()
    {
        $serviceAccount = storage_path('app/firebase-credentials.json');
        
        if (!file_exists($serviceAccount)) {
            throw new \Exception("Firebase credentials file not found at: $serviceAccount");
        }
        
        // Get access token using service account
        try {
            $factory = (new Factory)->withServiceAccount($serviceAccount);
            $this->accessToken = $factory->createAuth()->createCustomToken('server')->toString();
        } catch (\Exception $e) {
            \Log::error('Failed to initialize Firebase Auth', [
                'error' => $e->getMessage(),
            ]);
            // Continue without token for now - we'll use Firestore REST API directly
        }
    }

    /**
     * Get Firestore REST API URL
     */
    private function getFirestoreUrl(): string
    {
        return "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents";
    }

    /**
     * Get OAuth2 access token for service account
     */
    private function getAccessToken(): string
    {
        $serviceAccount = storage_path('app/firebase-credentials.json');
        $credentials = json_decode(file_get_contents($serviceAccount), true);
        
        // Use Google Auth library
        $scopes = ['https://www.googleapis.com/auth/datastore'];
        
        try {
            $creds = new \Google\Auth\Credentials\ServiceAccountCredentials($scopes, $credentials);
            $token = $creds->fetchAuthToken();
            
            if (isset($token['error'])) {
                throw new \Exception('Auth error: ' . json_encode($token));
            }
            
            return $token['access_token'];
        } catch (\Exception $e) {
            \Log::error('Failed to get access token', [
                'error' => $e->getMessage(),
                'project_id' => $credentials['project_id'] ?? 'unknown'
            ]);
            throw $e;
        }
    }

    /**
     * Create conversation between customer and mitra
     * Dipanggil setelah booking berhasil
     */
    public function createConversation(
        int $rideId,
        string $bookingType,
        int $customerId,
        string $customerName,
        ?string $customerPhoto,
        int $mitraId,
        string $mitraName,
        ?string $mitraPhoto
    ): string {
        try {
            $accessToken = $this->getAccessToken();
            $baseUrl = $this->getFirestoreUrl();
            
            // Create conversation document
            $now = date('c'); // ISO 8601 format
            $data = [
                'fields' => [
                    'rideId' => ['integerValue' => (string)$rideId],
                    'bookingType' => ['stringValue' => $bookingType],
                    'customerId' => ['integerValue' => (string)$customerId],
                    'customerName' => ['stringValue' => $customerName],
                    'customerPhoto' => ['stringValue' => $customerPhoto ?? ''],
                    'mitraId' => ['integerValue' => (string)$mitraId],
                    'mitraName' => ['stringValue' => $mitraName],
                    'mitraPhoto' => ['stringValue' => $mitraPhoto ?? ''],
                    'lastMessage' => ['stringValue' => ''],
                    'lastMessageAt' => ['timestampValue' => $now],
                    'unreadCustomer' => ['integerValue' => '0'],
                    'unreadMitra' => ['integerValue' => '0'],
                    'createdAt' => ['timestampValue' => $now],
                ]
            ];

            $response = Http::withToken($accessToken)
                ->post("{$baseUrl}/conversations", $data);

            if (!$response->successful()) {
                throw new \Exception('Failed to create conversation: ' . $response->body());
            }

            $result = $response->json();
            $conversationId = basename($result['name']); // Extract document ID from path

            \Log::info('✅ Conversation created successfully', [
                'conversation_id' => $conversationId,
                'ride_id' => $rideId,
                'customer_id' => $customerId,
                'mitra_id' => $mitraId,
            ]);

            return $conversationId;
        } catch (\Exception $e) {
            \Log::error('❌ Failed to create conversation', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'ride_id' => $rideId,
            ]);
            throw $e;
        }
    }

    /**
     * Send notification message to conversation
     * Contoh: "Booking dikonfirmasi", "Driver dalam perjalanan", dll
     */
    public function sendSystemMessage(
        string $conversationId,
        string $message
    ): void {
        try {
            $accessToken = $this->getAccessToken();
            $baseUrl = $this->getFirestoreUrl();
            $now = date('c');
            
            // Create message document
            $messageData = [
                'fields' => [
                    'senderId' => ['integerValue' => '0'],
                    'senderName' => ['stringValue' => 'System'],
                    'text' => ['stringValue' => $message],
                    'type' => ['stringValue' => 'system'],
                    'imageUrl' => ['stringValue' => ''],
                    'isRead' => ['booleanValue' => false],
                    'createdAt' => ['timestampValue' => $now],
                ]
            ];

            $response = Http::withToken($accessToken)
                ->post("{$baseUrl}/conversations/{$conversationId}/messages", $messageData);

            if (!$response->successful()) {
                throw new \Exception('Failed to send message: ' . $response->body());
            }

            // Update conversation last message
            $updateData = [
                'fields' => [
                    'lastMessage' => ['stringValue' => $message],
                    'lastMessageAt' => ['timestampValue' => $now],
                ]
            ];

            Http::withToken($accessToken)
                ->patch("{$baseUrl}/conversations/{$conversationId}?updateMask.fieldPaths=lastMessage&updateMask.fieldPaths=lastMessageAt", $updateData);

            $result = $response->json();
            $messageId = basename($result['name']);

            \Log::info('✅ System message sent', [
                'conversation_id' => $conversationId,
                'message_id' => $messageId,
            ]);
        } catch (\Exception $e) {
            \Log::error('❌ Failed to send system message', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'conversation_id' => $conversationId,
            ]);
        }
    }
}
