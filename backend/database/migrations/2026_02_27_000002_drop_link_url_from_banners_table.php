<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class DropLinkUrlFromBannersTable extends Migration
{
    public function up()
    {
        Schema::table('banners', function (Blueprint $table) {
            if (Schema::hasColumn('banners', 'link_url')) {
                $table->dropColumn('link_url');
            }
        });
    }

    public function down()
    {
        Schema::table('banners', function (Blueprint $table) {
            $table->text('link_url')->nullable();
        });
    }
}
