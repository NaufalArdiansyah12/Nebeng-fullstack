<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Mail;

class TestEmail extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'mail:test {email}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Test email configuration by sending a test email';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $email = $this->argument('email');

        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $this->error('Invalid email address!');
            return 1;
        }

        $this->info('Sending test email to: ' . $email);

        try {
            Mail::raw('This is a test email from Laravel. If you receive this, your email configuration is working correctly!', function ($message) use ($email) {
                $message->to($email)
                        ->subject('Test Email - Laravel Mail Configuration');
            });

            $this->info('✅ Test email sent successfully!');
            $this->info('Please check your inbox (and spam folder) for the test email.');
            return 0;
        } catch (\Exception $e) {
            $this->error('❌ Failed to send email!');
            $this->error('Error: ' . $e->getMessage());
            $this->line('');
            
            // Check if it's an authentication error
            if (strpos($e->getMessage(), '535') !== false || strpos($e->getMessage(), 'BadCredentials') !== false) {
                $this->warn('⚠️  AUTHENTICATION ERROR DETECTED!');
                $this->line('');
                $this->line('Masalah: Username atau Password tidak diterima oleh Gmail.');
                $this->line('');
                $this->line('Solusi:');
                $this->line('1. ✅ PASTIKAN menggunakan App Password, BUKAN password Gmail biasa!');
                $this->line('2. ✅ Cara membuat App Password:');
                $this->line('   - Buka: https://myaccount.google.com/security');
                $this->line('   - Aktifkan 2-Step Verification (WAJIB!)');
                $this->line('   - Klik "App passwords" (Kata sandi aplikasi)');
                $this->line('   - Pilih "Mail" dan "Other (Custom name)"');
                $this->line('   - Ketik "Laravel" dan klik Generate');
                $this->line('   - Copy password 16 karakter (tanpa spasi)');
                $this->line('');
                $this->line('3. ✅ Update file .env:');
                $this->line('   MAIL_USERNAME=ranggamagangjogja@gmail.com');
                $this->line('   MAIL_PASSWORD=xxxx xxxx xxxx xxxx  (16 karakter, tanpa spasi atau dengan spasi)');
                $this->line('');
                $this->line('4. ✅ Setelah update .env, jalankan:');
                $this->line('   php artisan config:clear');
                $this->line('');
            } else {
                $this->line('Please check:');
                $this->line('1. MAIL_MAILER is set to "smtp" in .env');
                $this->line('2. MAIL_HOST, MAIL_PORT, MAIL_USERNAME, MAIL_PASSWORD are correct');
                $this->line('3. For Gmail: Use App Password (not regular password)');
                $this->line('4. Check storage/logs/laravel.log for detailed error');
            }
            
            return 1;
        }
    }
}
