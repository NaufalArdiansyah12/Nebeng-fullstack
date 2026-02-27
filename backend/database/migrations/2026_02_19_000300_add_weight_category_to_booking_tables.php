<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Add weight_category_id to booking_barang
        if (Schema::hasTable('booking_barang')) {
            Schema::table('booking_barang', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_barang', 'weight_category_id')) {
                    $table->foreignId('weight_category_id')->nullable()->after('weight')->constrained('weight_categories')->nullOnDelete();
                }
            });
        }

        // Add weight_category_id to booking_titip_barang
        if (Schema::hasTable('booking_titip_barang')) {
            Schema::table('booking_titip_barang', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_titip_barang', 'weight_category_id')) {
                    $table->foreignId('weight_category_id')->nullable()->after('weight')->constrained('weight_categories')->nullOnDelete();
                }
            });
        }

        // Add weight_category_id to booking_motor (for hanya_barang and tebengan_dan_barang)
        if (Schema::hasTable('booking_motor')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_motor', 'weight_category_id')) {
                    $table->foreignId('weight_category_id')->nullable()->after('weight')->constrained('weight_categories')->nullOnDelete();
                }
            });
        }

        // Add weight_category_id to booking_mobil (for hanya_barang and tebengan_dan_barang)
        if (Schema::hasTable('booking_mobil')) {
            Schema::table('booking_mobil', function (Blueprint $table) {
                if (!Schema::hasColumn('booking_mobil', 'weight_category_id')) {
                    $table->foreignId('weight_category_id')->nullable()->after('weight')->constrained('weight_categories')->nullOnDelete();
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('booking_barang')) {
            Schema::table('booking_barang', function (Blueprint $table) {
                $table->dropForeign(['weight_category_id']);
                $table->dropColumn('weight_category_id');
            });
        }

        if (Schema::hasTable('booking_titip_barang')) {
            Schema::table('booking_titip_barang', function (Blueprint $table) {
                $table->dropForeign(['weight_category_id']);
                $table->dropColumn('weight_category_id');
            });
        }

        if (Schema::hasTable('booking_motor')) {
            Schema::table('booking_motor', function (Blueprint $table) {
                $table->dropForeign(['weight_category_id']);
                $table->dropColumn('weight_category_id');
            });
        }

        if (Schema::hasTable('booking_mobil')) {
            Schema::table('booking_mobil', function (Blueprint $table) {
                $table->dropForeign(['weight_category_id']);
                $table->dropColumn('weight_category_id');
            });
        }
    }
};
