<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('articles', function (Blueprint $table) {
            if (! Schema::hasColumn('articles', 'thumbnail')) {
                $table->string('thumbnail')->nullable()->after('category');
            }
            if (! Schema::hasColumn('articles', 'slug')) {
                $table->string('slug')->nullable()->unique()->after('title');
            }
            if (! Schema::hasColumn('articles', 'tags')) {
                $table->json('tags')->nullable()->after('excerpt');
            }
            if (! Schema::hasColumn('articles', 'status')) {
                $table->string('status', 24)->default('Published')->after('published');
            }
            if (! Schema::hasColumn('articles', 'published_at')) {
                $table->timestamp('published_at')->nullable()->after('status');
            }
            if (! Schema::hasColumn('articles', 'author')) {
                $table->string('author')->default('Admin S-Gizi')->after('published_at');
            }
            if (! Schema::hasColumn('articles', 'views_count')) {
                $table->unsignedInteger('views_count')->default(0)->after('author');
            }
            if (! Schema::hasColumn('articles', 'read_time')) {
                $table->unsignedSmallInteger('read_time')->default(1)->after('views_count');
            }
        });

        DB::table('articles')->orderBy('id')->get()->each(function ($article) {
            DB::table('articles')
                ->where('id', $article->id)
                ->update([
                    'slug' => $article->slug ?: Str::slug($article->title).'-'.$article->id,
                    'status' => ($article->published ?? true) ? 'Published' : 'Draft',
                    'published_at' => ($article->published ?? true) ? ($article->created_at ?? now()) : null,
                    'author' => $article->author ?: 'Admin S-Gizi',
                    'read_time' => max(1, (int) ceil(str_word_count(strip_tags((string) $article->content)) / 200)),
                ]);
        });
    }

    public function down(): void
    {
        Schema::table('articles', function (Blueprint $table) {
            foreach (['read_time', 'views_count', 'author', 'published_at', 'status', 'tags', 'slug', 'thumbnail'] as $column) {
                if (Schema::hasColumn('articles', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
