import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    lock: {
      executor: "constant-vus",
      vus: 20,
      duration: "1m",
    },
  },
};

const BASE = __ENV.BASE_URL;

export default function () {
  const res = http.post(`${BASE}/tx/lock`, JSON.stringify({ hold_ms: 10000 }), {
    headers: { "Content-Type": "application/json" },
    timeout: "60s",
  });
  check(res, {
    "lock path returned": (r) => r.status === 200 || r.status === 500,
  });
  sleep(0.2);
}
