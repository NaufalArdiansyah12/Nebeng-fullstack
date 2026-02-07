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
        Schema::table('posmitra_users', function (Blueprint $table) {
            if (Schema::hasColumn('posmitra_users', 'reward_points')) {
                $table->dropColumn('reward_points');
            }

            if (Schema::hasColumn('posmitra_users', 'address')) {
                $table->dropColumn('address');
            }
        });
    }


    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('posmitra_users', function (Blueprint $table) {
            $table->string('address')->nullable();
            $table->integer('reward_points')->default(0);
        });
    }
};
