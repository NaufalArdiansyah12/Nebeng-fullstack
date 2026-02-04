<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Verifikasi Nomor HP</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 40px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .logo {
            font-size: 32px;
            font-weight: bold;
            color: #1e40af;
            margin-bottom: 10px;
        }
        .otp-code {
            background-color: #eff6ff;
            border: 2px dashed #1e40af;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            margin: 30px 0;
        }
        .otp-code h2 {
            margin: 0;
            font-size: 42px;
            letter-spacing: 8px;
            color: #1e40af;
            font-weight: bold;
        }
        .info-box {
            background-color: #fef3c7;
            border-left: 4px solid #f59e0b;
            padding: 15px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            font-size: 12px;
            color: #6b7280;
        }
        .phone-info {
            background-color: #f3f4f6;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="logo">🚗 Nebeng</div>
            <h1 style="color: #1f2937; margin: 0;">Verifikasi Nomor HP</h1>
        </div>

        <p>Halo <strong>{{ $userName }}</strong>,</p>

        <p>Anda telah meminta kode verifikasi untuk nomor HP berikut:</p>

        <div class="phone-info">
            <strong>📱 Nomor HP:</strong> {{ $phone }}
        </div>

        <p>Gunakan kode OTP di bawah ini untuk menyelesaikan verifikasi:</p>

        <div class="otp-code">
            <p style="margin: 0; font-size: 14px; color: #6b7280; margin-bottom: 10px;">Kode Verifikasi Anda</p>
            <h2>{{ $otpCode }}</h2>
            <p style="margin: 10px 0 0 0; font-size: 12px; color: #6b7280;">Kode berlaku selama 10 menit</p>
        </div>

        <div class="info-box">
            <strong>⚠️ Perhatian:</strong>
            <ul style="margin: 10px 0; padding-left: 20px;">
                <li>Jangan bagikan kode ini kepada siapapun</li>
                <li>Tim Nebeng tidak akan pernah meminta kode OTP Anda</li>
                <li>Kode hanya dapat digunakan satu kali</li>
                <li>Maksimal 3 kali percobaan salah</li>
            </ul>
        </div>

        <p>Jika Anda tidak melakukan permintaan verifikasi ini, abaikan email ini dan segera ubah password akun Anda.</p>

        <div class="footer">
            <p>Email ini dikirim secara otomatis, mohon tidak membalas email ini.</p>
            <p>&copy; {{ date('Y') }} Nebeng App. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
