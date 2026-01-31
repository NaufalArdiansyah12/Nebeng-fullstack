<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CustomerRating extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'booking_type',
        'mitra_id',
        'customer_id',
        'rating',
        'feedback',
        'proof_image',
    ];

    protected $casts = [
        'rating' => 'integer',
    ];

    /**
     * Get the mitra (driver) who gave the rating
     */
    public function mitra()
    {
        return $this->belongsTo(User::class, 'mitra_id');
    }

    /**
     * Get the customer being rated
     */
    public function customer()
    {
        return $this->belongsTo(User::class, 'customer_id');
    }

    /**
     * Update customer's average rating after a rating is created/updated
     */
    public static function boot()
    {
        parent::boot();

        static::created(function ($rating) {
            self::updateCustomerAverageRating($rating->customer_id);
        });

        static::updated(function ($rating) {
            self::updateCustomerAverageRating($rating->customer_id);
        });

        static::deleted(function ($rating) {
            self::updateCustomerAverageRating($rating->customer_id);
        });
    }

    /**
     * Update customer's average rating
     */
    private static function updateCustomerAverageRating($customerId)
    {
        $ratings = self::where('customer_id', $customerId)->get();
        $totalRatings = $ratings->count();
        $averageRating = $totalRatings > 0 ? $ratings->avg('rating') : null;

        User::where('id', $customerId)->update([
            'customer_average_rating' => $averageRating,
            'customer_total_ratings' => $totalRatings,
        ]);
    }
}
