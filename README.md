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

## Deploy Render + Supabase

Frontend dan backend berjalan dalam **satu Render Web Service**. Saat build, Render membuat frontend Vite; Express menyajikan file hasil build sekaligus endpoint `/api/*`. Supabase hanya digunakan sebagai database PostgreSQL.

1. Push folder project ini ke GitHub.
2. Di Render, pilih **New → Blueprint** dan hubungkan repository. Biarkan Root Directory kosong (root repository). Render membaca `render.yaml` untuk membuat Web Service dan menjalankan `npm install --include=dev && npm run build -w client` saat build. Opsi `--include=dev` diperlukan agar Vite, Tailwind CSS, dan alat build lain tetap terpasang meski environment Render memakai `NODE_ENV=production`.
3. Buka project Supabase → **Connect** → pilih **Session pooler**. Salin connection string yang disediakan. Format username pooler bersama ialah `postgres.<PROJECT_REF>`; gunakan host persis seperti yang ditampilkan Supabase.
4. Pada Render Web Service `internship-log`, buka **Environment** dan isi `DATABASE_URL` dengan URI Supabase tersebut. Ganti placeholder password dengan **database password** project Supabase (bukan password login Supabase). Encode karakter khusus pada password sebagai URL encoding, dan tambahkan `?sslmode=require` jika URI yang disalin belum menyertakannya. Simpan.
5. Deploy service. Perintah start menjalankan migration Supabase lebih dahulu, kemudian memulai Express. Buka URL `onrender.com` service yang sama untuk memakai frontend; endpoint pemeriksaan tersedia di `/api/health`.

Jika log migration menampilkan `password authentication failed`, periksa nilai `DATABASE_URL` pada Environment Render: URI Session pooler harus memakai username `postgres.<PROJECT_REF>` dan password database yang benar. Bila password tidak diketahui, reset database password di Supabase lalu perbarui URI di Render. Setelah mengubah environment, simpan dan deploy ulang. Jangan menaruh `DATABASE_URL` di GitHub.

Untuk memeriksa koneksi dari lingkungan lokal, atur `DATABASE_URL` pada `server/.env`, lalu jalankan `npm run check-db -w server`. Untuk menguji deployment, buka `https://<nama-service>.onrender.com/api/health` dan pastikan responsnya `{"ok":true}`. Layanan gratis Render dapat tidur saat tidak digunakan sehingga pembukaan pertama mungkin perlu menunggu proses startup. Supabase menyediakan PostgreSQL yang tetap terpisah dari layanan aplikasi Render.

Buat backup rutin PostgreSQL dan uji pemulihannya. Database Supabase baru tidak otomatis berisi data dari database lokal.

## Batasan saat ini

- Belum ada automated integration test atau UI test; fitur belum diklaim terverifikasi dengan suite pengujian.
- Proteksi CSRF belum menggunakan token khusus; cookie SameSite=Lax menjadi lapisan awal perlindungan.
- Impor menerima CSV/XLSX, maksimum 5 MB/500 baris; deteksi duplikat belum ditambahkan. CSV dengan koma/quote kompleks perlu dibersihkan sebelum impor.
- Ekspor PDF adalah laporan teks ringkas. Laporan harian/mingguan/bulanan dapat difilter melalui rentang tanggal, belum berupa preset terpisah.
- Backup dijelaskan sebagai prosedur operasional; aplikasi tidak menjalankan backup otomatis.
