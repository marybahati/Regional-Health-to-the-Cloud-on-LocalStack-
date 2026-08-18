'use strict';

const express = require('express');
const { loadDbCredentials, getSecretSource, clearCache } = require('./secrets');
const { getPool, poolStats, ping, closePool } = require('./db');
const metrics = require('./metrics');

const PORT = Number(process.env.PORT || 3000);
const BIND_HOST = process.env.BIND_HOST || '0.0.0.0';
const SERVICE_NAME = process.env.SERVICE_NAME || 'service-a';
const SERVICE_B_URL = process.env.SERVICE_B_URL || '';

const app = express();
app.use(express.json({ limit: '1mb' }));
app.use(metrics.middleware);

let bootError = null;
let ready = false;

app.get('/healthz', (_req, res) => {
  res.status(200).json({ service: SERVICE_NAME, status: 'ok' });
});

app.get('/readyz', async (_req, res) => {
  if (bootError) {
    return res.status(503).json({ status: 'not_ready', reason: 'secret_failed', error: bootError });
  }
  const stats = poolStats();
  metrics.observePool(stats);
  if (stats.saturated) {
    return res.status(503).json({ status: 'not_ready', reason: 'pool_saturated', pool: stats });
  }
  try {
    await ping();
    res.status(200).json({
      status: 'ready',
      secret: getSecretSource(),
      pool: stats,
    });
  } catch (err) {
    res.status(503).json({ status: 'not_ready', reason: 'db_unreachable', error: err.message });
  }
});

app.get('/debug/secret-source', (_req, res) => {
  res.status(200).json(getSecretSource());
});

app.get('/metrics', async (_req, res) => {
  metrics.observePool(poolStats());
  res.set('Content-Type', metrics.register.contentType);
  res.end(await metrics.register.metrics());
});

app.get('/patients', async (req, res) => {
  try {
    const p = await getPool();
    const q = (req.query.q || '').toString();
    const fault = process.env.FAULT_2201 === '1';
    const sql = fault
      ? 'SELECT * FROM patients WHERE notes LIKE ?'
      : 'SELECT id, national_id, full_name, district FROM patients WHERE national_id = ? LIMIT 20';
    const param = fault ? `%${q}%` : q;
    const [rows] = await p.query(sql, [param]);
    metrics.rowsExamined.inc({ service: metrics.SERVICE, route: '/patients' }, fault ? 10000 : rows.length);
    res.status(200).json({ count: rows.length, rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/patients/:id', async (req, res) => {
  try {
    const p = await getPool();
    const [rows] = await p.query(
      'SELECT id, national_id, full_name, district, date_of_birth FROM patients WHERE id = ?',
      [req.params.id]
    );
    if (!rows.length) return res.status(404).json({ error: 'not_found' });
    res.status(200).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/export', async (req, res) => {
  try {
    const p = await getPool();
    if (process.env.FAULT_2204 === '1') {
      const [rows] = await p.query('SELECT * FROM patients');
      const blob = JSON.stringify(rows);
      const copies = [];
      for (let i = 0; i < 80; i += 1) copies.push(blob);
      const payload = copies.join('');
      return res.status(200).json({ bytes: payload.length, rows: rows.length });
    }
    const [rows] = await p.query('SELECT id, national_id FROM patients LIMIT 100');
    res.status(200).json({ rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/tx/lock', async (req, res) => {
  const holdMs = Number(req.body?.hold_ms || process.env.LOCK_HOLD_MS || 8000);
  const started = Date.now();
  let conn;
  try {
    const p = await getPool();
    conn = await p.getConnection();
    await conn.beginTransaction();
    await conn.query('SELECT id FROM patients WHERE id = 1 FOR UPDATE');
    if (process.env.FAULT_2203 === '1') {
      await new Promise((r) => setTimeout(r, holdMs));
    }
    await conn.commit();
    const waited = (Date.now() - started) / 1000;
    metrics.lockWaitSeconds.observe({ service: metrics.SERVICE }, waited);
    res.status(200).json({ held_ms: Date.now() - started });
  } catch (err) {
    if (conn) await conn.rollback().catch(() => {});
    const waited = (Date.now() - started) / 1000;
    metrics.lockWaitSeconds.observe({ service: metrics.SERVICE }, waited);
    res.status(500).json({ error: err.message, code: err.code });
  } finally {
    if (conn) conn.release();
  }
});

app.post('/pool/hold', async (req, res) => {
  const holdMs = Number(req.body?.hold_ms || 15000);
  let conn;
  try {
    const p = await getPool();
    conn = await p.getConnection();
    if (process.env.FAULT_2202 === '1') {
      await new Promise((r) => setTimeout(r, holdMs));
    }
    res.status(200).json({ held_ms: holdMs, pool: poolStats() });
  } catch (err) {
    res.status(500).json({ error: err.message, pool: poolStats() });
  } finally {
    if (conn) conn.release();
  }
});

app.get('/greet-service-b', async (req, res) => {
  if (!SERVICE_B_URL) {
    return res.status(200).json({
      status: 'standalone',
      message: 'Service B is not in this checkout; teammates rehost B and C.',
    });
  }
  try {
    const r = await fetch(`${SERVICE_B_URL}/greet`, {
      headers: { 'X-Request-ID': req.headers['x-request-id'] || 'service-a' },
    });
    const body = await r.json();
    res.status(r.status).json(body);
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

app.post('/debug/reload-secret', async (_req, res) => {
  clearCache();
  await closePool();
  try {
    await loadDbCredentials();
    await ping();
    bootError = null;
    res.status(200).json(getSecretSource());
  } catch (err) {
    bootError = err.message;
    res.status(500).json({ error: err.message });
  }
});

async function boot() {
  try {
    await loadDbCredentials();
    await ping();
    ready = true;
    bootError = null;
  } catch (err) {
    bootError = err.message;
    console.error(JSON.stringify({ event: 'boot_failed', error: err.message }));
  }
  app.listen(PORT, BIND_HOST, () => {
    console.log(JSON.stringify({
      event: 'listen',
      service: SERVICE_NAME,
      port: PORT,
      ready,
      secret: getSecretSource(),
    }));
  });
}

boot();
