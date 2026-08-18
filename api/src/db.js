'use strict';

const mysql = require('mysql2/promise');
const { loadDbCredentials } = require('./secrets');

let pool = null;

async function getPool() {
  if (pool) return pool;
  const creds = await loadDbCredentials();
  const ssl = creds.ca
    ? { ca: creds.ca, rejectUnauthorized: true }
    : process.env.MYSQL_SSL === '0'
      ? undefined
      : { rejectUnauthorized: true };
  pool = mysql.createPool({
    host: creds.host,
    port: creds.port,
    user: creds.username,
    password: creds.password,
    database: creds.dbname,
    waitForConnections: true,
    connectionLimit: Number(process.env.MYSQL_POOL_SIZE || 10),
    queueLimit: Number(process.env.MYSQL_QUEUE_LIMIT || 20),
    enableKeepAlive: true,
    connectTimeout: 10000,
    ssl,
  });
  pool.on('error', (err) => {
    console.error(JSON.stringify({ event: 'mysql_pool_error', code: err.code, message: err.message }));
  });
  return pool;
}

function poolStats() {
  if (!pool) return { total: 0, free: 0, queued: 0, saturated: false };
  const p = pool.pool;
  const total = p._allConnections.length;
  const free = p._freeConnections.length;
  const queued = p._connectionQueue.length;
  const limit = p.config.connectionLimit;
  return {
    total,
    free,
    queued,
    limit,
    saturated: queued > 0 && free === 0,
  };
}

async function ping() {
  const p = await getPool();
  try {
    const [rows] = await p.query('SELECT 1 AS ok');
    return rows[0].ok === 1;
  } catch (err) {
    await closePool();
    throw err;
  }
}

async function closePool() {
  if (!pool) return;
  const closing = pool;
  pool = null;
  closing.on('error', () => {});
  try {
    await closing.end();
  } catch {
    // Auth failures during drain are expected when the secret was rotated.
  }
}

module.exports = { getPool, poolStats, ping, closePool };
