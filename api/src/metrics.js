'use strict';

const client = require('prom-client');

const register = new client.Registry();
client.collectDefaultMetrics({ register, prefix: 'service_a_' });

const httpDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration seconds',
  labelNames: ['service', 'method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5, 10],
  registers: [register],
});

const httpRequests = new client.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['service', 'method', 'route', 'status_code'],
  registers: [register],
});

const rowsExamined = new client.Counter({
  name: 'mysql_rows_examined_total',
  help: 'Rows examined reported by handler stats (proxy via query rows)',
  labelNames: ['service', 'route'],
  registers: [register],
});

const poolInUse = new client.Gauge({
  name: 'mysql_pool_in_use',
  help: 'Connections currently checked out of the pool',
  labelNames: ['service'],
  registers: [register],
});

const poolQueued = new client.Gauge({
  name: 'mysql_pool_queued',
  help: 'Waiters queued for a pool connection',
  labelNames: ['service'],
  registers: [register],
});

const lockWaitSeconds = new client.Histogram({
  name: 'mysql_lock_wait_seconds',
  help: 'Observed lock wait time',
  labelNames: ['service'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10, 30, 60],
  registers: [register],
});

const processRestarts = new client.Counter({
  name: 'process_restart_total',
  help: 'Process starts (incremented once at boot)',
  labelNames: ['service'],
  registers: [register],
});

const rssBytes = new client.Gauge({
  name: 'process_resident_memory_bytes',
  help: 'RSS bytes',
  labelNames: ['service'],
  registers: [register],
});

const SERVICE = process.env.SERVICE_NAME || 'service-a';
processRestarts.inc({ service: SERVICE });

function observePool(stats) {
  poolInUse.set({ service: SERVICE }, Math.max(0, (stats.total || 0) - (stats.free || 0)));
  poolQueued.set({ service: SERVICE }, stats.queued || 0);
}

function observeMemory() {
  rssBytes.set({ service: SERVICE }, process.memoryUsage().rss);
}

function middleware(req, res, next) {
  const end = httpDuration.startTimer();
  res.on('finish', () => {
    const route = req.route ? req.route.path : req.path;
    const labels = {
      service: SERVICE,
      method: req.method,
      route,
      status_code: String(res.statusCode),
    };
    end(labels);
    httpRequests.inc(labels);
    observeMemory();
  });
  next();
}

module.exports = {
  register,
  middleware,
  rowsExamined,
  lockWaitSeconds,
  observePool,
  SERVICE,
};
