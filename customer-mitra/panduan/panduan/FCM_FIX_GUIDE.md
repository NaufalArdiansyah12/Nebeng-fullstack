# Panduan Fix FCM Push Notification "Invalid JWT Signature"

## Masalah Teridentifikasi

**Root Cause:** Service account private key tidak valid/revoked di Google Cloud
- Log error: `OAuth token request failed {"status":400,"body":"{\"error\":\"invalid_grant\",\"error_description\":\"Invalid JWT Signature.\"}"}`
- File service account ada di: `/home/naufal/project/nebeng-fullstack/customer-mitra/keys/nebeng1-firebase-adminsdk-fbsvc-fc76eb0bc7.json`
- JWT creation berhasil lokal, tapi Google menolak signature → key sudah tidak valid

## Solusi: Regenerate Service Account Key

### Langkah 1: Download Service Account Baru

1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Pilih project **nebeng1**
3. Klik ⚙️ (Settings) → **Project Settings**
4. Tab **Service Accounts**
5. Klik **Generate new private key**
6. Konfirmasi dan download file JSON

### Langkah 2: Replace File di Server

```bash
# Backup file lama
cp /home/naufal/project/nebeng-fullstack/customer-mitra/keys/nebeng1-firebase-adminsdk-fbsvc-fc76eb0bc7.json \
   /home/naufal/project/nebeng-fullstack/customer-mitra/keys/nebeng1-firebase-adminsdk-OLD-$(date +%Y%m%d).json

# Copy file baru yang didownload (sesuaikan nama file)
cp ~/Downloads/nebeng1-firebase-adminsdk-xxxxx-NEW.json \
   /home/naufal/project/nebeng-fullstack/customer-mitra/keys/nebeng1-firebase-adminsdk-fbsvc-fc76eb0bc7.json

# Set permission
chmod 600 /home/naufal/project/nebeng-fullstack/customer-mitra/keys/nebeng1-firebase-adminsdk-fbsvc-fc76eb0bc7.json
```

### Langkah 3: Validasi File Baru

```bash
# Test JWT signature dengan Google OAuth
php -r '
$sa=json_decode(file_get_contents("/home/naufal/project/nebeng-fullstack/customer-mitra/keys/nebeng1-firebase-adminsdk-fbsvc-fc76eb0bc7.json"), true);
function base64UrlEncode($data) { return rtrim(strtr(base64_encode($data), "+/", "-_"), "="); }
$now = time();
$header = ["alg" => "RS256", "typ" => "JWT"];
$claims = [
    "iss" => $sa["client_email"],
    "scope" => "https://www.googleapis.com/auth/firebase.messaging",
    "aud" => "https://oauth2.googleapis.com/token",
    "exp" => $now + 3600,
    "iat" => $now,
];
$headerEncoded = base64UrlEncode(json_encode($header));
$claimsEncoded = base64UrlEncode(json_encode($claims));
$unsigned = $headerEncoded . "." . $claimsEncoded;
openssl_sign($unsigned, $signature, $sa["private_key"], OPENSSL_ALGO_SHA256);
$sigEncoded = base64UrlEncode($signature);
$jwt = $unsigned . "." . $sigEncoded;

$ch = curl_init("https://oauth2.googleapis.com/token");
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => http_build_query([
        "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion" => $jwt,
    ]),
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ["Content-Type: application/x-www-form-urlencoded"],
]);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: $httpCode\n";
$json = json_decode($response, true);
if(isset($json["access_token"])) {
    echo "✓ OAuth SUCCESS - Service account key is VALID!\n";
} else {
    echo "✗ OAuth FAILED - Key still invalid\n";
    echo "Response: $response\n";
}
'
```

Expected output: `✓ OAuth SUCCESS - Service account key is VALID!`

### Langkah 4: Restart Services

```bash
# Restart PHP-FPM (jika pakai)
sudo systemctl restart php8.1-fpm

# Restart queue workers (jika pakai Laravel queue)
cd /home/naufal/project/nebeng-fullstack/backend
php artisan queue:restart

# Atau restart service worker Anda
```

### Langkah 5: Test FCM Sending

```bash
# Pantau log real-time
tail -f /home/naufal/project/nebeng-fullstack/backend/storage/logs/laravel.log
```

Lakukan test payment atau trigger webhook, cari log:
- ✅ `FCM v1 sent` → berhasil
- ❌ `OAuth token request failed` → gagal (perlu cek lagi)

## Verification Checklist

- [ ] Service account JSON baru didownload dari Firebase Console
- [ ] File di-copy ke path yang benar: `customer-mitra/keys/nebeng1-firebase-adminsdk-fbsvc-fc76eb0bc7.json`
- [ ] Permission file: `chmod 600`
- [ ] Validasi OAuth berhasil (script di atas return SUCCESS)
- [ ] PHP-FPM/workers sudah direstart
- [ ] Test payment → notifikasi terkirim
- [ ] Log menunjukkan `FCM v1 sent`

## Alternative: Update .env Path

Jika mau menggunakan lokasi berbeda untuk service account file:

```bash
# Edit .env
nano /home/naufal/project/nebeng-fullstack/backend/.env

# Update baris:
FCM_SERVICE_ACCOUNT=/path/to/new/location/service-account.json

# Restart services
php artisan config:clear
php artisan cache:clear
php artisan queue:restart
```

## Troubleshooting

### Jika masih error "Invalid JWT Signature"
1. Pastikan waktu server tersinkronisasi: `timedatectl status`
2. Cek file permission: `ls -l customer-mitra/keys/*.json`
3. Verifikasi project_id match: `jq .project_id customer-mitra/keys/nebeng1-*.json`
4. Generate NEW key lagi (mungkin ada issue saat download pertama)

### Jika error "service account not configured"
1. Cek .env: `grep FCM_SERVICE_ACCOUNT backend/.env`
2. Cek file exists: `ls -l /path/from/.env`
3. Restart cache: `php artisan config:clear`

## Referensi

- [Firebase Admin SDK Setup](https://firebase.google.com/docs/admin/setup)
- [FCM HTTP v1 API](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [Service Account Keys](https://cloud.google.com/iam/docs/keys-create-delete)
