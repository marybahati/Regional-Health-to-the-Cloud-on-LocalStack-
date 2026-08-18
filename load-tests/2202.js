import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    hold: {
      executor: "constant-vus",
      vus: 30,
      duration: "1m",
    },
  },
};

const BASE = __ENV.BASE_URL;

export default function () {
  const res = http.post(`${BASE}/pool/hold`, JSON.stringify({ hold_ms: 8000 }), {
    headers: { "Content-Type": "application/json" },
    timeout: "30s",
  });
  check(res, { "got a response": (r) => r.status === 200 || r.status === 500 });
  sleep(0.2);
}
