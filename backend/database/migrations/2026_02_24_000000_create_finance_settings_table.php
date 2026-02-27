<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('finance_settings', function (Blueprint $table) {
            $table->id();
            $table->decimal('admin_fee', 15, 2)->default(0);
            $table->decimal('reschedule_fee', 15, 2)->default(0);
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('finance_settings');
    }
};
