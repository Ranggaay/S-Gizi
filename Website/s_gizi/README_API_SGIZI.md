# API S-Gizi (Laravel)

## Endpoint

### POST `/api/hasil`

Input JSON:

```json
{
  "jenis_kelamin": "L",
  "tanggal_lahir": "2023-01-01",
  "tanggal_ukur": "2026-04-21",
  "berat_badan": 12.5,
  "tinggi_badan": 90.0,
  "cara_ukur": "standing"
}
```

Output (contoh struktur):

```json
{
  "zscore": { "bbu": -1.23, "tbu": -2.8, "bbtb": 0.45 },
  "kategori": { "bbu": "Normal", "tbu": "Pendek", "bbtb": "Normal" },
  "status_gabungan": "Stunting",
  "rekomendasi": [
    {
      "menu": "Nasi + Ayam + Sayur",
      "protein": 15,
      "kalori": 250,
      "lemak": 8,
      "karbohidrat": 30,
      "alasan": "Disarankan makanan tinggi protein dan mikronutrien untuk mendukung pertumbuhan tinggi badan."
    }
  ]
}
```

## Import data LMS WHO dari Flutter

Data LMS bersumber dari file:

- `Android/flutter_app/assets/data/lms_who_final.json`

Jalankan:

```bash
php artisan migrate
php artisan db:seed --class=LMSSeeder
```

Opsional contoh seed makanan:

```bash
php artisan db:seed --class=MakananSeeder
```

