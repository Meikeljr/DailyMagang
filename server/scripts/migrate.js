import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { pool, printDatabaseConnectionError } from '../src/config/database.js';

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL belum diatur. Tambahkan URI Supabase Session pooler di Render → service API → Environment.');
  process.exit(1);
}

try {
  await pool.query('SELECT 1');
  for (const name of ['001_initial.sql', '002_username_primary_key.sql']) {
    const sql = await readFile(new URL(`../migrations/${name}`, import.meta.url), 'utf8');
    await pool.query(sql);
    console.log(`Migration ${name} applied.`);
  }
} catch (error) {
  printDatabaseConnectionError(error, 'Migration');
  process.exitCode = 1;
} finally {
  await pool.end();
}
