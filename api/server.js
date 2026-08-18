'use strict';

const express = require('express');
const { getSecretSource } = require('./secrets');
const { initDatabase, checkDatabase } = require('./database');

const PORT = Number(process.env.PORT) || 3002;
const BIND_HOST = process.env.BIND_HOST || '0.0.0.0';
const SERVICE_NAME = process.env.SERVICE_NAME || 'service-b';

const app = express();

app.get('/healthz', (_req, res) => {
  res.status(200).json({
    service: SERVICE_NAME,
    status: 'ok',
  });
});

app.get('/readyz', async (_req, res) => {
  const db = await checkDatabase();
  if (!db.ok) {
    res.status(503).json({
      service: SERVICE_NAME,
      status: 'not_ready',
      reason: db.reason,
    });
    return;
  }

  res.status(200).json({
    service: SERVICE_NAME,
    status: 'ready',
  });
});

app.get('/debug/secret-source', (_req, res) => {
  res.status(200).json(getSecretSource());
});

app.get('/metrics', (_req, res) => {
  res.type('text/plain').send('# service-b metrics placeholder\n');
});

async function start() {
  await initDatabase();
  app.listen(PORT, BIND_HOST, () => {
    const source = getSecretSource();
    console.log(
      JSON.stringify({
        event: 'service_started',
        service: SERVICE_NAME,
        port: PORT,
        secret_arn: source.arn,
        secret_version: source.versionId,
      })
    );
  });
}

start().catch((error) => {
  console.error(
    JSON.stringify({
      event: 'service_start_failed',
      error: error.message,
    })
  );
  process.exit(1);
});
