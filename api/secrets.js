'use strict';

const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require('@aws-sdk/client-secrets-manager');

let cachedCreds = null;
let secretSource = { arn: 'env', versionId: 'n/a' };

function buildClientConfig() {
  const config = { region: process.env.AWS_REGION || 'us-east-1' };
  if (process.env.AWS_ENDPOINT_URL) {
    config.endpoint = process.env.AWS_ENDPOINT_URL;
  }
  return config;
}

function envFallback() {
  return {
    host: process.env.MYSQL_HOST || process.env.DB_HOST,
    port: Number(process.env.MYSQL_PORT || process.env.DB_PORT || 3306),
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
    database: process.env.MYSQL_DATABASE || process.env.DB_NAME || 'capacity_lab',
  };
}

async function loadDbCredentials() {
  if (cachedCreds) {
    return cachedCreds;
  }

  const secretArn = process.env.DB_SECRET_ARN;
  if (!secretArn) {
    cachedCreds = envFallback();
    secretSource = { arn: 'env', versionId: 'n/a' };
    return cachedCreds;
  }

  const client = new SecretsManagerClient(buildClientConfig());
  const response = await client.send(
    new GetSecretValueCommand({ SecretId: secretArn })
  );
  const envelope = JSON.parse(response.SecretString);

  cachedCreds = {
    host: envelope.host,
    port: Number(envelope.port),
    user: envelope.username,
    password: envelope.password,
    database: envelope.dbname,
  };
  secretSource = {
    arn: response.ARN || secretArn,
    versionId: response.VersionId || 'unknown',
  };

  console.log(
    JSON.stringify({
      event: 'db_credentials_loaded',
      secret_arn: secretSource.arn,
      secret_version: secretSource.versionId,
    })
  );

  return cachedCreds;
}

function getSecretSource() {
  return { ...secretSource };
}

module.exports = { loadDbCredentials, getSecretSource };
