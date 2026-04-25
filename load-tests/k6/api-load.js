import http from 'k6/http';
import { check, sleep } from 'k6';

const baseUrl = __ENV.BASE_URL || 'http://localhost:8080';
const vus = Number(__ENV.K6_VUS || 20);
const duration = __ENV.K6_DURATION || '30s';

export const options = {
  vus,
  duration,
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<800', 'p(99)<1500'],
  },
};

function randomSuffix() {
  return `${__VU}-${__ITER}-${Date.now()}`;
}

function registerUser() {
  const suffix = randomSuffix();
  const payload = JSON.stringify({
    username: `load_${suffix}`,
    email: `load_${suffix}@habitduel.dev`,
    password: 'loadtest123',
  });

  const response = http.post(`${baseUrl}/auth/register`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { name: 'auth_register' },
  });

  check(response, {
    'register status is 201': (r) => r.status === 201,
    'register returns token': (r) => !!r.json('token'),
  });

  return response;
}

function authHeaders(token) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };
}

export default function () {
  const registerResponse = registerUser();
  if (registerResponse.status !== 201) {
    sleep(1);
    return;
  }

  const token = registerResponse.json('token');

  const meResponse = http.get(`${baseUrl}/users/me`, {
    headers: { Authorization: `Bearer ${token}` },
    tags: { name: 'users_me' },
  });
  check(meResponse, {
    'me status is 200': (r) => r.status === 200,
  });

  const createDuelResponse = http.post(
    `${baseUrl}/duels`,
    JSON.stringify({
      habit_name: 'Load Test Habit',
      description: 'k6 smoke duel',
      duration_days: 7,
    }),
    {
      ...authHeaders(token),
      tags: { name: 'duels_create' },
    },
  );
  check(createDuelResponse, {
    'create duel status is 201': (r) => r.status === 201,
  });

  const listResponse = http.get(`${baseUrl}/duels`, {
    headers: { Authorization: `Bearer ${token}` },
    tags: { name: 'duels_list' },
  });
  check(listResponse, {
    'list duels status is 200': (r) => r.status === 200,
  });

  const leaderboardResponse = http.get(`${baseUrl}/leaderboard`, {
    headers: { Authorization: `Bearer ${token}` },
    tags: { name: 'leaderboard' },
  });
  check(leaderboardResponse, {
    'leaderboard is reachable': (r) => r.status === 200 || r.status === 307 || r.status === 308,
  });

  sleep(1);
}
