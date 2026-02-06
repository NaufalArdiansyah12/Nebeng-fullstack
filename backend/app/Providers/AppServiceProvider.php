<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Contract\Firestore;
use Illuminate\Support\Facades\Log;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Register Firebase Firestore
        $this->app->singleton(Firestore::class, function ($app) {
            try {
                $serviceAccountPath = config('firebase.credentials');
                
                if (empty($serviceAccountPath)) {
                    Log::error('Firebase credentials path not configured');
                    throw new \Exception('Firebase credentials not configured');
                }
                
                if (!file_exists($serviceAccountPath)) {
                    Log::error('Firebase credentials file not found: ' . $serviceAccountPath);
                    throw new \Exception('Firebase credentials file not found');
                }
                
                $factory = (new Factory)
                    ->withServiceAccount($serviceAccountPath)
                    ->withDatabaseUri('https://nebeng1-default-rtdb.firebaseio.com');
                    
                return $factory->createFirestore();
            } catch (\Exception $e) {
                Log::error('Failed to initialize Firestore: ' . $e->getMessage());
                throw $e;
            }
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
