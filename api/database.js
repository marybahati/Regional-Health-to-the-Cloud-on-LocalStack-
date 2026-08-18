'use strict';

const mysql = require('mysql2/promise');
const { loadDbCredentials } = require('./secrets');

let pool = null;
let ready = false;
let lastError = null;

const POOL_LIMIT = Number(process.env.DB_POOL_LIMIT || 10);

async function initDatabase() {
  if (process.env.SKIP_DB === '1') {
    ready = true;
    return;
  }

  const creds = await loadDbCredentials();
  if (!creds.host || !creds.user) {
    throw new Error('database_credentials_incomplete');
  }

  pool = mysql.createPool({
    host: creds.host,
    port: creds.port,
    user: creds.user,
    password: creds.password,
    database: creds.database,
    waitForConnections: true,
    connectionLimit: POOL_LIMIT,
    queueLimit: 0,
    ssl: process.env.MYSQL_SSL_CA
      ? { ca: process.env.MYSQL_SSL_CA }
      : { rejectUnauthorized: false },
  });

  const connection = await pool.getConnection();
  try {
    await connection.ping();
    ready = true;
    lastError = null;
  } finally {
    connection.release();
  }
}

async function checkDatabase() {
  if (process.env.SKIP_DB === '1') {
    return { ok: true };
  }

  if (!pool) {
    return { ok: false, reason: 'pool_not_initialized' };
  }

  try {
    const connection = await pool.getConnection();
    try {
      await connection.ping();
      ready = true;
      lastError = null;
      return { ok: true };
    } finally {
      connection.release();
    }
  } catch (error) {
    ready = false;
    lastError = error.message;
    return { ok: false, reason: error.message };
  }
}

function isReady() {
  return ready;
}

function getLastError() {
  return lastError;
}

module.exports = {
  initDatabase,
  checkDatabase,
  isReady,
  getLastError,
};
