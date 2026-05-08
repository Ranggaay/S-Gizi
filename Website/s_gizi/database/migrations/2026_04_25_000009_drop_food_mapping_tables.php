<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::dropIfExists('food_conditions');
        Schema::dropIfExists('foods');
    }

    public function down(): void
    {
        // No rollback creation for deprecated mapping tables.
    }
};
