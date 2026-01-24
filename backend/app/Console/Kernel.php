<?php

namespace App\Console;

use Illuminate\Foundation\Console\Kernel as ConsoleKernel;
use Illuminate\Console\Scheduling\Schedule;
use App\Console\Commands\AutoStartTrips;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        AutoStartTrips::class,
    ];

    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule)
    {
        // Run the auto-start command every minute
        $schedule->command('trips:auto-start')->everyMinute();
    }

    /**
     * Register the commands for the application.
     */
    protected function commands()
    {
        // auto-discovery from Commands folder
        $this->load(__DIR__ . '/Commands');
    }
}
