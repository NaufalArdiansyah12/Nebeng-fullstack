<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddPhotoWeightDescriptionToBookingMotor extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (!Schema::hasColumn('booking_motor', 'photo') ||
            !Schema::hasColumn('booking_motor', 'weight') ||
            !Schema::hasColumn('booking_motor', 'description')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_motor', 'photo')) {
                    $table->string('photo')->nullable()->after('meta');
                }
                if (!Schema::hasColumn('booking_motor', 'weight')) {
                    $table->string('weight')->nullable()->after('photo');
                }
                if (!Schema::hasColumn('booking_motor', 'description')) {
                    $table->text('description')->nullable()->after('weight');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('booking_motor', function (Blueprint $table) {
            if (Schema::hasColumn('booking_motor', 'description')) {
                $table->dropColumn('description');
            }
            if (Schema::hasColumn('booking_motor', 'weight')) {
                $table->dropColumn('weight');
            }
            if (Schema::hasColumn('booking_motor', 'photo')) {
                $table->dropColumn('photo');
            }
        });
    }
}
