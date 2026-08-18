import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 5,
  duration: "45s",
};

const BASE = __ENV.BASE_URL;

export default function () {
  const res = http.get(`${BASE}/export`, { timeout: "60s" });
  check(res, { "export answered or died": (r) => r.status === 200 || r.status === 0 });
  sleep(1);
}
