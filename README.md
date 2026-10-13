# IT Support Internship Log

Aplikasi full-stack untuk mencatat kegiatan magang IT Support. Frontend React/Vite dan API Express terhubung ke PostgreSQL. Setiap catatan diikat pada session pengguna.

## Persyaratan

- Node.js 20 atau lebih baru
- PostgreSQL 14 atau lebih baru

## Menjalankan secara lokal

1. Buat database, misalnya `internship_log`, di PostgreSQL.
2. Salin `server/.env.example` menjadi `server/.env`, lalu sesuaikan `DATABASE_URL` dan ganti `SESSION_SECRET` dengan nilai acak panjang. Salin `client/.env.example` ke `client/.env` bila URL API berbeda.
3. Dari root jalankan `npm install`.
4. Jalankan migration: `npm run migrate -w server`.
5. Jalankan frontend dan backend: `npm run dev`.
6. Buka `http://localhost:5173`, pilih Daftar, lalu login dengan username yang ditampilkan setelah pendaftaran.

## Fitur

- Registrasi dengan username pilihan pengguna sebagai primary key, password bcrypt, login/logout, session PostgreSQL, dan cookie HttpOnly.
- CRUD kegiatan dengan validasi tanggal, jam satu hari, mode multi-hari, tempat bebas, dan status dari progress.
- Pencarian kegiatan, ringkasan tanggal yang mencakup rentang, dashboard aktual, laporan dan ekspor CSV/XLSX/PDF.
- Preview dan konfirmasi impor CSV/XLSX.
- Pembatasan pemilik catatan di semua endpoint kegiatan.

## Migrasi dan database

Migration berada di `server/migrations/`. Skrip `npm run migrate -w server` menerapkan skema awal lalu peningkatan username-primary-key, dan aman dijalankan kembali. Constraint database memaksa tanggal valid, progress 0–100, dan aturan jam sesuai kegiatan satu atau beberapa hari.

## Pengujian manual

- Buat dua akun; buat kegiatan berbeda di masing-masing akun. Login bergantian dan pastikan daftar, rangkuman, dashboard, laporan, dan ekspor hanya menunjukkan milik akun aktif. Endpoint detail/update/delete memakai kombinasi ID dan user session, sehingga ID lintas akun memberi 404.
- Simpan kegiatan dengan tanggal sama dan isi jam selesai setelah jam mulai. Coba jam invalid dan pastikan ditolak. Ubah menjadi rentang beberapa hari; input jam hilang dan disimpan null. Ubah kembali menjadi satu hari; input jam muncul kosong.
- Pilih beberapa tanggal di antara tanggal mulai dan selesai pada Rangkuman Harian. Kedua batas termasuk, tanggal di luar rentang tidak termasuk.
- Uji ekspor melalui tombol pada Laporan; impor menampilkan preview sebelum konfirmasi dan menyertakan laporan baris gagal.

## Production

Jalankan `npm run build`, deploy `client/dist` sebagai frontend statis dan `server` pada Node.js, siapkan PostgreSQL terkelola/mandiri, jalankan migration pada deployment, dan set `DATABASE_URL`, `SESSION_SECRET`, `CLIENT_ORIGIN`, `NODE_ENV=production`, serta `VITE_API_URL`. Gunakan HTTPS; secure cookie aktif otomatis pada production. Buat backup rutin PostgreSQL (`pg_dump`) dan uji pemulihan dengan `pg_restore`. Pastikan frontend dan API memakai origin/CORS/cookie yang sesuai bila domain berbeda.

## Batasan saat ini

- Belum ada automated integration test atau UI test; fitur belum diklaim terverifikasi dengan suite pengujian.
- Proteksi CSRF belum menggunakan token khusus; SameSite=Lax dan pemeriksaan origin CORS menjadi lapisan awal, dan deployment lintas situs perlu menambahkan strategi CSRF yang sesuai.
- Impor menerima CSV/XLSX, maksimum 5 MB/500 baris; deteksi duplikat belum ditambahkan. CSV dengan koma/quote kompleks perlu dibersihkan sebelum impor.
- Ekspor PDF adalah laporan teks ringkas. Laporan harian/mingguan/bulanan dapat difilter melalui rentang tanggal, belum berupa preset terpisah.
- Backup dijelaskan sebagai prosedur operasional; aplikasi tidak menjalankan backup otomatis.
