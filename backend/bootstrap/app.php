<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // Exclude API routes from CSRF verification so mobile/JS clients
        // can POST to /api/* without needing a CSRF token.
        \Illuminate\Foundation\Http\Middleware\VerifyCsrfToken::except(['api/*']);
        
        // Add CORS middleware globally for API
        $middleware->append(\App\Http\Middleware\CorsMiddleware::class);
        
        // Add middleware aliases
        $middleware->alias([
            'check.user.status' => \App\Http\Middleware\CheckUserStatus::class,
            'admin.auth' => \App\Http\Middleware\AdminAuthMiddleware::class,
            'auth.api.token' => \App\Http\Middleware\AuthenticateWithApiToken::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
