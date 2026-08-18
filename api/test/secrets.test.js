'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { loadDbCredentials, getSecretSource, clearCache } = require('../src/secrets');

test('falls back to MYSQL_* when DB_SECRET_ARN is unset', async () => {
  clearCache();
  delete process.env.DB_SECRET_ARN;
  process.env.MYSQL_USER = 'app';
  process.env.MYSQL_PASSWORD = 'x';
  process.env.MYSQL_HOST = '127.0.0.1';
  process.env.MYSQL_PORT = '3306';
  process.env.MYSQL_DATABASE = 'capacity_lab';
  const creds = await loadDbCredentials();
  assert.equal(creds.username, 'app');
  assert.equal(creds.host, '127.0.0.1');
  assert.equal(creds.dbname, 'capacity_lab');
  const src = getSecretSource();
  assert.equal(src.arn, 'env');
  assert.equal(src.versionId, 'n/a');
});
