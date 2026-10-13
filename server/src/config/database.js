import pg from 'pg';

export const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });

export function databaseTarget() {
  try {
    const url = new URL(process.env.DATABASE_URL || '');
    return {
      host: url.hostname,
      port: url.port || '5432',
      database: url.pathname.replace(/^\//, '') || '(default)',
      username: decodeURIComponent(url.username),
      isSupabasePooler: url.hostname.endsWith('.pooler.supabase.com'),
      hasSslMode: Boolean(url.searchParams.get('sslmode')),
    };
  } catch {
    return null;
  }
}

export function printDatabaseConnectionError(error, context = 'Aplikasi') {
  const target = databaseTarget();
  console.error(`${context}: koneksi PostgreSQL gagal.`);
  if (target) {
    console.error(`Target: ${target.host}:${target.port}/${target.database}; user=${target.username}; sslmode=${target.hasSslMode ? 'disetel' : 'tidak tampak di URI'}.`);
    if (target.isSupabasePooler && target.username === 'postgres') {
      console.error('URI memakai Supabase Session Pooler tetapi user-nya hanya "postgres". Salin ulang URI Session pooler dari Supabase Connect; username pooler harus berbentuk postgres.<PROJECT_REF>.');
    }
  }
  if (error?.code === '28P01') {
    console.error('Supabase menolak password. Pastikan DATABASE_URL berisi password database project ini, bukan password akun Supabase. Jika password berisi karakter khusus, URL-encode sebelum memasukkannya ke URI.');
    console.error('Perbarui DATABASE_URL pada environment service hosting setelah memastikan password database benar, lalu deploy ulang.');
  } else if (error?.code === 'ENOTFOUND' || error?.code === 'ECONNREFUSED' || error?.code === 'ETIMEDOUT') {
    console.error('Periksa host/port Supabase dan gunakan URI Session pooler dari menu Connect.');
  }
  console.error(`Kode PostgreSQL: ${error?.code || 'tidak tersedia'}; pesan: ${error?.message || 'tidak tersedia'}`);
}
