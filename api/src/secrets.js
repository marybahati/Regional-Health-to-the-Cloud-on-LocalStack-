'use strict';

const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

let cached = null;
let source = { arn: 'unset', versionId: 'n/a' };

function client() {
  const endpoint = process.env.AWS_ENDPOINT_URL;
  return new SecretsManagerClient({
    region: process.env.AWS_DEFAULT_REGION || 'us-east-1',
    ...(endpoint ? { endpoint } : {}),
  });
}

function fromEnv() {
  return {
    engine: 'mysql',
    username: process.env.MYSQL_USER || process.env.MYSQL_USERNAME,
    password: process.env.MYSQL_PASSWORD,
    host: process.env.MYSQL_HOST || process.env.DB_HOST,
    port: Number(process.env.MYSQL_PORT || process.env.DB_PORT || 3306),
    dbname: process.env.MYSQL_DATABASE || process.env.MYSQL_DB || 'defaultdb',
    ca: process.env.MYSQL_CA || process.env.AIVEN_MYSQL_CA || '',
  };
}

async function loadDbCredentials() {
  if (cached) return cached;

  const arn = process.env.DB_SECRET_ARN;
  if (!arn) {
    cached = fromEnv();
    source = { arn: 'env', versionId: 'n/a' };
    console.log(JSON.stringify({ event: 'secret_source', arn: source.arn, versionId: source.versionId }));
    return cached;
  }

  const out = await client().send(new GetSecretValueCommand({ SecretId: arn }));
  const parsed = JSON.parse(out.SecretString);
  cached = {
    engine: parsed.engine,
    username: parsed.username,
    password: parsed.password,
    host: parsed.host,
    port: Number(parsed.port || 3306),
    dbname: parsed.dbname,
    ca: parsed.ca || '',
  };
  source = { arn: out.ARN || arn, versionId: out.VersionId || 'n/a' };
  console.log(JSON.stringify({ event: 'secret_source', arn: source.arn, versionId: source.versionId }));
  return cached;
}

function getSecretSource() {
  return { arn: source.arn, versionId: source.versionId };
}

function clearCache() {
  cached = null;
}

module.exports = { loadDbCredentials, getSecretSource, clearCache };
