<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('api_tokens', function (Blueprint $table) {
            // Add posmitra_id column - nullable, foreign key to posmitra_users
            $table->unsignedBigInteger('posmitra_id')->nullable()->after('user_id');
            $table->foreign('posmitra_id')->references('id')->on('posmitra_users')->onDelete('cascade');
            
            // Make user_id nullable (if not already)
            $table->unsignedBigInteger('user_id')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('api_tokens', function (Blueprint $table) {
            $table->dropForeign(['posmitra_id']);
            $table->dropColumn('posmitra_id');
        });
    }
};
