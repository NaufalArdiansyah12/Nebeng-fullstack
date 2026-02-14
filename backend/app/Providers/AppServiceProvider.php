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
                    error_log('Firebase credentials path not configured');
                    return null;
                }
                
                if (!file_exists($serviceAccountPath)) {
                    error_log('Firebase credentials file not found: ' . $serviceAccountPath);
                    return null;
                }
                
                $factory = (new Factory)
                    ->withServiceAccount($serviceAccountPath)
                    ->withDatabaseUri('https://nebeng1-default-rtdb.firebaseio.com');
                    
                return $factory->createFirestore();
            } catch (\Exception $e) {
                error_log('Failed to initialize Firestore: ' . $e->getMessage());
                return null;
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
