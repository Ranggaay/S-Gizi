<?php

namespace App\Services;

use App\Models\Food;

class MenuService
{
    /**
     * Ambil makanan berdasarkan status_gizi (mapping di food_conditions).
     * Menu:
     * - pagi/siang/malam: 2 makanan
     * - snack: kategori vitamin (1-2 item, default 2 jika tersedia)
     *
     * @return array{pagi: array<int, array{id:int,nama:string,kategori:string}>, siang: array<int, array{id:int,nama:string,kategori:string}>, malam: array<int, array{id:int,nama:string,kategori:string}>, snack: array<int, array{id:int,nama:string,kategori:string}>}
     */
    public function generate(string $statusGabungan): array
    {
        $foodsForStatus = Food::query()
            ->select('foods.*')
            ->join('food_conditions', 'food_conditions.food_id', '=', 'foods.id')
            ->where('food_conditions.status_gizi', $statusGabungan)
            ->inRandomOrder()
            ->get();

        $snacks = Food::query()
            ->whereRaw('LOWER(kategori) = ?', ['vitamin'])
            ->inRandomOrder()
            ->limit(2)
            ->get();

        $pick = fn ($collection, int $n) => $collection
            ->take($n)
            ->map(fn (Food $f) => ['id' => $f->id, 'nama' => $f->nama, 'kategori' => $f->kategori])
            ->values()
            ->all();

        return [
            'pagi' => $pick($foodsForStatus->slice(0), 2),
            'siang' => $pick($foodsForStatus->slice(2), 2),
            'malam' => $pick($foodsForStatus->slice(4), 2),
            'snack' => $snacks->map(fn (Food $f) => ['id' => $f->id, 'nama' => $f->nama, 'kategori' => $f->kategori])->values()->all(),
        ];
    }
}

