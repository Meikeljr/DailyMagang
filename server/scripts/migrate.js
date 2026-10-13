import 'dotenv/config';
import pg from 'pg';
import { readFile } from 'node:fs/promises';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
for (const name of ['001_initial.sql', '002_username_primary_key.sql']) {
  const sql = await readFile(new URL(`../migrations/${name}`, import.meta.url), 'utf8');
  await pool.query(sql);
  console.log(`Migration ${name} applied.`);
}
await pool.end();
