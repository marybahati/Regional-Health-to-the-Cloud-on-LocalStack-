import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    search: {
      executor: "constant-vus",
      vus: 50,
      duration: "2m",
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.05"],
  },
};

const BASE = __ENV.BASE_URL;

export default function () {
  const q = `UG${String(Math.floor(Math.random() * 10000) + 1).padStart(8, "0")}`;
  const res = http.get(`${BASE}/patients?q=${q}`);
  check(res, { "2201 status 200": (r) => r.status === 200 });
  sleep(0.1);
}
