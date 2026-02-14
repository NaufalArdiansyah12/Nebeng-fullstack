<?php

namespace App\Services;

use App\Models\User;
use App\Models\PosMitraUser;
use Kreait\Firebase\Contract\Firestore;

class PosMitraConversationService
{
    protected $firestore;

    public function __construct(?Firestore $firestore = null)
    {
        $this->firestore = $firestore;
    }

    /**
     * Check if Firebase is available
     */
    protected function isFirebaseAvailable(): bool
    {
        return $this->firestore !== null;
    }

    /**
     * Create conversations between mitra and pos mitra (origin & destination)
     * 
     * @param int $mitraUserId - ID user mitra yang membuat tebengan
     * @param int $originLocationId - ID lokasi asal
     * @param int $destinationLocationId - ID lokasi tujuan
     * @param string $tebenganType - Tipe tebengan (motor/mobil)
     * @return array ['origin_conversation_id' => string, 'destination_conversation_id' => string]
     */
    public function createTebenganConversations(
        int $mitraUserId, 
        int $originLocationId, 
        int $destinationLocationId,
        string $tebenganType = 'motor'
    ): array {
        // Check if Firebase is available
        if (!$this->isFirebaseAvailable()) {
            error_log('Firebase not available, skipping conversation creation');
            return [
                'origin_conversation_id' => null,
                'destination_conversation_id' => null,
            ];
        }
        $result = [
            'origin_conversation_id' => null,
            'destination_conversation_id' => null
        ];

        try {
            // Find pos mitra user for origin location
            $originPosMitra = PosMitraUser::where('location_id', $originLocationId)
                ->first();

            // Find pos mitra user for destination location
            $destinationPosMitra = PosMitraUser::where('location_id', $destinationLocationId)
                ->first();

            // Create conversation with origin pos mitra
            if ($originPosMitra) {
                $result['origin_conversation_id'] = $this->createConversation(
                    $mitraUserId,
                    $originPosMitra->id,
                    'mitra',
                    'posmitra',
                    "Pos Asal",
                    $tebenganType
                );
            } else {
                error_log("No pos mitra found for origin location: $originLocationId");
            }

            // Create conversation with destination pos mitra
            if ($destinationPosMitra) {
                $result['destination_conversation_id'] = $this->createConversation(
                    $mitraUserId,
                    $destinationPosMitra->id,
                    'mitra',
                    'posmitra',
                    "Pos Tujuan",
                    $tebenganType
                );
            } else {
                error_log("No pos mitra found for destination location: $destinationLocationId");
            }

            return $result;
        } catch (\Exception $e) {
            error_log("Error creating pos mitra conversations: " . $e->getMessage());
            return $result;
        }
    }

    /**
     * Create a single conversation in Firebase
     * 
     * @param int $user1Id
     * @param int $user2Id
     * @param string $user1Role
     * @param string $user2Role
     * @param string $context
     * @param string $tebenganType
     * @return string|null conversation ID
     */
    protected function createConversation(
        int $user1Id,
        int $user2Id,
        string $user1Role,
        string $user2Role,
        string $context = "",
        string $tebenganType = "motor"
    ): ?string {
        try {
            // Sort user IDs to ensure consistent conversation ID
            $participantIds = [$user1Id, $user2Id];
            sort($participantIds);
            
            // Generate conversation ID based on participants and context
            $conversationId = "conv_" . implode('_', $participantIds) . "_" . md5($context . time());

            // Get user details
            $user1 = User::find($user1Id);
            $user2 = null;
            
            // Check if user2 is a PosMitra user
            if ($user2Role === 'posmitra') {
                $user2 = PosMitraUser::find($user2Id);
            }
            
            // Fallback to regular User table
            if (!$user2) {
                $user2 = User::find($user2Id);
            }

            if (!$user1 || !$user2) {
                error_log("User not found: user1=$user1Id, user2=$user2Id");
                return null;
            }

            // Create conversation document in Firebase
            $currentTimestamp = \Carbon\Carbon::now()->toIso8601String();
            
            $conversationData = [
                'participants' => [
                    (string)$user1Id => [
                        'user_id' => $user1Id,
                        'name' => $user1->name,
                        'role' => $user1Role,
                        'phone' => $user1->phone ?? '',
                        'unread_count' => 0,
                        'last_read_at' => $currentTimestamp,
                    ],
                    (string)$user2Id => [
                        'user_id' => $user2Id,
                        'name' => $user2->name,
                        'role' => $user2Role,
                        'phone' => $user2->phone ?? '',
                        'unread_count' => 0,
                        'last_read_at' => $currentTimestamp,
                    ],
                ],
                'last_message' => '',
                'last_message_at' => $currentTimestamp,
                'context' => $context,
                'tebengan_type' => $tebenganType,
                'conversation_type' => 'mitra_posmitra',
                'created_at' => $currentTimestamp,
                'updated_at' => $currentTimestamp,
            ];

            // Save to Firestore
            $this->firestore
                ->database()
                ->collection('conversations')
                ->document($conversationId)
                ->set($conversationData);

            error_log("Created conversation: $conversationId between mitra $user1Id and posmitra $user2Id ($tebenganType - $context)");

            return $conversationId;
        } catch (\Exception $e) {
            error_log("Error creating conversation: " . $e->getMessage());
            return null;
        }
    }

    /**
     * Get pos mitra user for a location
     * 
     * @param int $locationId
     * @return PosMitraUser|null
     */
    public function getPosMitraForLocation(int $locationId): ?PosMitraUser
    {
        return PosMitraUser::where('location_id', $locationId)
            ->first();
    }

    /**
     * Get location name
     * 
     * @param int $locationId
     * @return string
     */
    public function getLocationName(int $locationId): string
    {
        $location = \App\Models\Location::find($locationId);
        return $location ? $location->name : "Lokasi #$locationId";
    }
}
