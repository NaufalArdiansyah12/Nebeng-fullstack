<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::table('payments', function (Blueprint $table) {
            if (!Schema::hasColumn('payments', 'reschedule_request_id')) {
                $table->unsignedBigInteger('reschedule_request_id')->nullable()->after('booking_id');
            }
        });
    }

    public function down()
    {
        Schema::table('payments', function (Blueprint $table) {
            if (Schema::hasColumn('payments', 'reschedule_request_id')) {
                $table->dropColumn('reschedule_request_id');
            }
        });
    }
};
