<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Cache;

class FcmService
{
    /**
     * Send a notification to a device token using FCM HTTP v1 API.
     * Requires `FCM_SERVICE_ACCOUNT` env pointing to service account JSON file.
     */
    public static function sendToToken(string $token, string $title, string $body, array $data = []): bool
    {
        $serviceAccountPath = env('FCM_SERVICE_ACCOUNT');

        if (empty($serviceAccountPath) || !file_exists($serviceAccountPath)) {
            Log::warning('FCM service account not configured or file not found: ' . ($serviceAccountPath ?? 'null'));
            return false;
        }

        $sa = json_decode(file_get_contents($serviceAccountPath), true);
        if (!$sa) {
            Log::error('Unable to parse service account JSON');
            return false;
        }

        $projectId = $sa['project_id'] ?? env('FCM_PROJECT_ID');
        if (empty($projectId)) {
            Log::error('FCM project_id not found in service account and FCM_PROJECT_ID not set');
            return false;
        }

        try {
            $accessToken = self::getAccessToken($sa);
            if (empty($accessToken)) {
                Log::error('Could not obtain FCM access token');
                return false;
            }

            $url = "https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send";

            $message = [
                'message' => [
                    'token' => $token,
                    'notification' => [
                        'title' => $title,
                        'body' => $body,
                    ],
                    'data' => array_map('strval', $data),
                ],
            ];

            Log::info('FCM v1 request', ['url' => $url, 'message' => $message]);

            $resp = Http::withToken($accessToken)
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($url, $message);

            Log::info('FCM v1 response', ['status' => $resp->status(), 'body' => $resp->body()]);

            if ($resp->successful()) {
                Log::info('FCM v1 sent', ['to' => $token]);
                return true;
            }

            Log::error('FCM v1 error', ['status' => $resp->status(), 'body' => $resp->body()]);
            return false;
        } catch (\Exception $e) {
            Log::error('FCM v1 Exception: ' . $e->getMessage(), ['exception' => $e]);
            return false;
        }
    }

    /**
     * Obtain OAuth2 access token from service account using JWT exchange.
     */
    protected static function getAccessToken(array $sa): ?string
    {
        $cacheKey = 'fcm_v1_access_token_' . ($sa['client_email'] ?? '');
        if (Cache::has($cacheKey)) {
            return Cache::get($cacheKey);
        }

        $now = time();
        $expiry = $now + 3600;

        $header = ['alg' => 'RS256', 'typ' => 'JWT'];
        $claims = [
            'iss' => $sa['client_email'],
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud' => 'https://oauth2.googleapis.com/token',
            'exp' => $expiry,
            'iat' => $now,
        ];

        $jwt = self::encodeJwt($header, $claims, $sa['private_key']);
        if (!$jwt) {
            Log::error('Failed to build JWT for service account');
            return null;
        }

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion' => $jwt,
        ]);

        if (!$response->successful()) {
            Log::error('OAuth token request failed', ['status' => $response->status(), 'body' => $response->body()]);
            return null;
        }

        $body = $response->json();
        $accessToken = $body['access_token'] ?? null;
        $expiresIn = $body['expires_in'] ?? 3600;

        if ($accessToken) {
            Cache::put($cacheKey, $accessToken, now()->addSeconds($expiresIn - 60));
        }

        return $accessToken;
    }

    protected static function base64UrlEncode(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    protected static function encodeJwt(array $header, array $claims, string $privateKey): ?string
    {
        $headerEncoded = self::base64UrlEncode(json_encode($header));
        $claimsEncoded = self::base64UrlEncode(json_encode($claims));
        $unsigned = $headerEncoded . '.' . $claimsEncoded;

        $signature = '';
        $ok = openssl_sign($unsigned, $signature, $privateKey, OPENSSL_ALGO_SHA256);
        if (!$ok) {
            Log::error('OpenSSL sign failed when creating JWT');
            return null;
        }

        $sigEncoded = self::base64UrlEncode($signature);
        return $unsigned . '.' . $sigEncoded;
    }

}
