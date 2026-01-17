<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Payment;
use Carbon\Carbon;

class SimulatePayment extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'payment:simulate {payment_id? : The payment ID to simulate}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Simulate payment success for testing (development only)';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        if (!app()->environment('local', 'development')) {
            $this->error('This command is only available in development mode');
            return 1;
        }

        $paymentId = $this->argument('payment_id');

        if (!$paymentId) {
            // Show pending payments
            $this->showPendingPayments();
            
            $paymentId = $this->ask('Enter Payment ID to simulate');
            
            if (!$paymentId) {
                $this->error('Payment ID is required');
                return 1;
            }
        }

        return $this->simulatePayment($paymentId);
    }

    private function showPendingPayments()
    {
        $payments = Payment::where('status', 'pending')
            ->with(['user'])
            ->orderBy('created_at', 'desc')
            ->get();

        if ($payments->isEmpty()) {
            $this->info('No pending payments found.');
            return;
        }

        $this->info('Pending Payments:');
        $this->newLine();

        $headers = ['ID', 'Booking Number', 'Method', 'Amount', 'VA Number', 'Created At'];
        $rows = [];

        foreach ($payments as $payment) {
            $rows[] = [
                $payment->id,
                $payment->booking_number ?? '-',
                strtoupper($payment->payment_method),
                'Rp ' . number_format($payment->total_amount, 0, ',', '.'),
                $payment->virtual_account_number ?? '-',
                $payment->created_at->format('Y-m-d H:i:s'),
            ];
        }

        $this->table($headers, $rows);
        $this->newLine();
    }

    private function simulatePayment($paymentId)
    {
        try {
            $payment = Payment::findOrFail($paymentId);

            if ($payment->status === 'paid') {
                $this->warn('Payment already paid!');
                return 0;
            }

            // Update payment status
            $payment->update([
                'status' => 'paid',
                'paid_at' => Carbon::now(),
            ]);

            // Update ride payment status if exists
            if ($payment->ride) {
                $payment->ride->update(['payment_status' => 'paid']);
            }

            // Update booking status
            $this->updateBookingStatus($payment);

            $this->info('✅ Payment simulated successfully!');
            $this->newLine();
            
            $this->info("Payment ID: {$payment->id}");
            $this->info("Booking: {$payment->booking_number}");
            $this->info("Amount: Rp " . number_format($payment->total_amount, 0, ',', '.'));
            $this->info("Status: {$payment->status}");
            $this->info("Paid At: {$payment->paid_at}");

            return 0;
        } catch (\Exception $e) {
            $this->error('Failed to simulate payment: ' . $e->getMessage());
            return 1;
        }
    }

    private function updateBookingStatus($payment)
    {
        try {
            // Try by booking_id first
            if ($payment->booking_id) {
                $booking = \App\Models\Booking::find($payment->booking_id);
                if ($booking) {
                    $booking->update(['status' => 'paid']);
                    return;
                }

                $bookingMobil = \App\Models\BookingMobil::find($payment->booking_id);
                if ($bookingMobil) {
                    $bookingMobil->update(['status' => 'paid']);
                    return;
                }

                $bookingBarang = \App\Models\BookingBarang::find($payment->booking_id);
                if ($bookingBarang) {
                    $bookingBarang->update(['status' => 'paid']);
                    return;
                }

                $bookingTitip = \App\Models\BookingTitipBarang::find($payment->booking_id);
                if ($bookingTitip) {
                    $bookingTitip->update(['status' => 'paid']);
                    return;
                }
            }

            // Try by booking_number
            if ($payment->booking_number) {
                $booking = \App\Models\Booking::where('booking_number', $payment->booking_number)->first();
                if ($booking) {
                    $booking->update(['status' => 'paid']);
                    return;
                }

                $bookingMobil = \App\Models\BookingMobil::where('booking_number', $payment->booking_number)->first();
                if ($bookingMobil) {
                    $bookingMobil->update(['status' => 'paid']);
                    return;
                }

                $bookingBarang = \App\Models\BookingBarang::where('booking_number', $payment->booking_number)->first();
                if ($bookingBarang) {
                    $bookingBarang->update(['status' => 'paid']);
                    return;
                }

                $bookingTitip = \App\Models\BookingTitipBarang::where('booking_number', $payment->booking_number)->first();
                if ($bookingTitip) {
                    $bookingTitip->update(['status' => 'paid']);
                    return;
                }
            }
        } catch (\Exception $e) {
            $this->warn('Could not update booking status: ' . $e->getMessage());
        }
    }
}
