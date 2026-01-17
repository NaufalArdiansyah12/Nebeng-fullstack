<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Payment;

class ListPendingPayments extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'payment:pending {--watch : Watch for new pending payments}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'List all pending payments';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        if ($this->option('watch')) {
            $this->watchPayments();
        } else {
            $this->listPayments();
        }
    }

    private function listPayments()
    {
        $payments = Payment::where('status', 'pending')
            ->with(['user'])
            ->orderBy('created_at', 'desc')
            ->get();

        if ($payments->isEmpty()) {
            $this->info('No pending payments found.');
            return;
        }

        $this->info('📋 Pending Payments (' . $payments->count() . ')');
        $this->newLine();

        $headers = ['ID', 'User', 'Booking', 'Method', 'Amount', 'VA Number', 'Expires At', 'Created'];
        $rows = [];

        foreach ($payments as $payment) {
            $expiresAt = $payment->expires_at 
                ? $payment->expires_at->format('Y-m-d H:i') 
                : '-';
            
            $isExpired = $payment->expires_at && $payment->expires_at->isPast();
            $expiresDisplay = $isExpired ? "❌ {$expiresAt}" : $expiresAt;

            $rows[] = [
                $payment->id,
                $payment->user->name ?? '-',
                $payment->booking_number ?? '-',
                strtoupper($payment->payment_method),
                'Rp ' . number_format($payment->total_amount, 0, ',', '.'),
                $payment->virtual_account_number ?? '-',
                $expiresDisplay,
                $payment->created_at->format('m-d H:i'),
            ];
        }

        $this->table($headers, $rows);
        $this->newLine();
        $this->info('💡 To simulate payment: php artisan payment:simulate <payment_id>');
    }

    private function watchPayments()
    {
        $this->info('👀 Watching for pending payments... (Press Ctrl+C to stop)');
        $this->newLine();

        $lastCount = 0;

        while (true) {
            $count = Payment::where('status', 'pending')->count();

            if ($count != $lastCount) {
                $this->newLine();
                $this->info('🔔 Payment count changed: ' . $count);
                $this->listPayments();
                $lastCount = $count;
            }

            sleep(5); // Check every 5 seconds
        }
    }
}
