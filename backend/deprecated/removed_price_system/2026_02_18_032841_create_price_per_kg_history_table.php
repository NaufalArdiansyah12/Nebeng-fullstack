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
        Schema::create('price_per_kg_history', function (Blueprint $table) {
            $table->id();
            $table->foreignId('price_per_kg_id')->constrained('price_per_kg')->onDelete('cascade');
            $table->enum('action', ['created', 'updated', 'activated', 'deactivated', 'deleted'])->comment('Jenis perubahan');
            $table->enum('service_type', ['antar_barang', 'antar_penumpang']);
            $table->enum('ride_type', ['motor', 'mobil', 'barang', 'titip_barang']);
            $table->decimal('rate_per_kg', 10, 2);
            $table->decimal('min_charge', 10, 2);
            $table->boolean('is_active');
            $table->date('effective_from');
            $table->foreignId('changed_by')->nullable()->constrained('users')->onDelete('set null')->comment('User yang melakukan perubahan');
            $table->text('notes')->nullable()->comment('Catatan perubahan');
            $table->timestamp('changed_at')->useCurrent();
            $table->timestamps();

            $table->index('price_per_kg_id');
            $table->index('changed_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('price_per_kg_history');
    }
};
