import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { pool, printDatabaseConnectionError } from '../src/config/database.js';

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL belum diatur. Tambahkan URI Supabase Session pooler di environment server.');
  process.exit(1);
}

try {
  try {
    await pool.query('SELECT 1');
  } catch (error) {
    printDatabaseConnectionError(error, 'Pemeriksaan koneksi sebelum migration');
    process.exitCode = 1;
  }

  if (process.exitCode !== 1) {
    for (const name of ['001_initial.sql', '002_username_primary_key.sql']) {
      try {
        const sql = await readFile(new URL(`../migrations/${name}`, import.meta.url), 'utf8');
        await pool.query(sql);
        console.log(`Migration ${name} applied.`);
      } catch (error) {
        console.error(`Migration ${name} gagal diterapkan.`);
        console.error(`Kode PostgreSQL: ${error?.code || 'tidak tersedia'}`);
        console.error(`Pesan: ${error?.message || 'tidak tersedia'}`);
        if (error?.detail) console.error(`Detail: ${error.detail}`);
        if (error?.hint) console.error(`Petunjuk PostgreSQL: ${error.hint}`);
        process.exitCode = 1;
        break;
      }
    }
  }
} finally {
  await pool.end();
}
