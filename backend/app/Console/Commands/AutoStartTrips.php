<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Booking;
use App\Models\BookingMobil;
use App\Models\BookingBarang;
use App\Models\BookingTitipBarang;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class AutoStartTrips extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'trips:auto-start';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Automatically set bookings to in_progress when departure datetime has passed';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $models = [Booking::class, BookingMobil::class, BookingBarang::class, BookingTitipBarang::class];
        $now = Carbon::now()->toDateTimeString();

        foreach ($models as $model) {
            try {
                $model::whereIn('status', ['paid', 'confirmed', 'pending'])
                    ->whereHas('ride', function ($q) use ($now) {
                        // Compare combined departure_date + departure_time to now
                        $q->whereRaw("CONCAT(departure_date, ' ', departure_time) <= ?", [$now]);
                    })
                    ->chunkById(100, function ($bookings) {
                        foreach ($bookings as $b) {
                            $b->status = 'in_progress';
                            $b->trip_started_at = $b->trip_started_at ?? now();
                            $b->save();
                            Log::info('AutoStartTrips: set booking to in_progress', ['booking_id' => $b->id]);
                        }
                    });
            } catch (\Exception $e) {
                Log::warning('AutoStartTrips failed for model ' . $model, ['error' => $e->getMessage()]);
            }
        }

        return 0;
    }
}
