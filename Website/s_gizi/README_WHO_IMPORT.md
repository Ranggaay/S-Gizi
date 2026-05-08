# Import Data WHO LMS (Wajib)

API ini menghitung Z-score **berdasarkan tabel LMS WHO**, jadi Anda harus mengisi tabel:

- `who_lms_age` untuk indikator:
  - `bbu` (BB/U)
  - `tbu` (TB/U)
- `who_lms_wfh` untuk indikator:
  - BB/TB (berat terhadap tinggi)

## Format tabel

### 1) `who_lms_age`

Kolom utama:

- `indikator`: `bbu` atau `tbu`
- `jenis_kelamin`: `L` atau `P`
- `umur_bulan`: bulan (biasanya 0..60)
- `l`, `m`, `s`

### 2) `who_lms_wfh`

Kolom utama:

- `jenis_kelamin`: `L` atau `P`
- `tinggi`: cm (biasanya step 0.1)
- `l`, `m`, `s`

## Sumber data

Gunakan tabel LMS resmi **WHO Child Growth Standards** (format L, M, S).

## Catatan

- Sistem akan melakukan **interpolasi linear** jika input umur/tinggi berada di antara titik LMS yang tersedia.
- Pastikan data LMS terisi sebelum mencoba endpoint `POST /api/hasil`, kalau tidak API akan gagal karena LMS tidak ditemukan.

