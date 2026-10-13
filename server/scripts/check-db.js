import 'dotenv/config';
import { pool, databaseTarget, printDatabaseConnectionError } from '../src/config/database.js';

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL belum diatur. Tambahkan URI Supabase Session pooler di Render → service API → Environment.');
  process.exit(1);
}

try {
  await pool.query('SELECT 1');
  const target = databaseTarget();
  console.log(`Koneksi PostgreSQL berhasil: ${target.host}:${target.port}/${target.database} (user=${target.username}).`);
} catch (error) {
  printDatabaseConnectionError(error, 'Pemeriksaan koneksi');
  process.exitCode = 1;
} finally {
  await pool.end();
}
