import http from 'k6/http';
import { check } from 'k6';

export var BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export function uniqueSuffix() {
  return __VU + '-' + __ITER + '-' + Date.now();
}

export function jsonHeaders(token) {
  var headers = {
    'Content-Type': 'application/json',
  };

  if (token) {
    headers.Authorization = 'Bearer ' + token;
  }

  return headers;
}

export function tagOptions(tagName, token) {
  return {
    headers: jsonHeaders(token),
    tags: { name: tagName },
  };
}

export function createUser(prefix) {
  var suffix = uniqueSuffix();
  return {
    username: prefix + '_' + suffix,
    email: prefix + '_' + suffix + '@habitduel.dev',
    password: 'loadtest123',
  };
}

export function registerUser(user, tagName) {
  return http.post(
    BASE_URL + '/auth/register',
    JSON.stringify(user),
    tagOptions(tagName || 'auth_register', null),
  );
}

export function loginUser(user, tagName) {
  return http.post(
    BASE_URL + '/auth/login',
    JSON.stringify({
      email: user.email,
      password: user.password,
    }),
    tagOptions(tagName || 'auth_login', null),
  );
}

export function getCurrentUser(token, tagName) {
  return http.get(
    BASE_URL + '/users/me',
    tagOptions(tagName || 'users_me', token),
  );
}

export function getLeaderboard(token, tagName) {
  return http.get(
    BASE_URL + '/leaderboard/',
    tagOptions(tagName || 'leaderboard', token),
  );
}

export function listDuels(token, tagName) {
  return http.get(
    BASE_URL + '/duels/',
    tagOptions(tagName || 'duels_list', token),
  );
}

export function getDuel(token, duelId, tagName) {
  return http.get(
    BASE_URL + '/duels/' + duelId,
    tagOptions(tagName || 'duels_detail', token),
  );
}

export function createDirectedDuel(token, habitName, durationDays, opponentUsername, tagName) {
  return http.post(
    BASE_URL + '/duels/',
    JSON.stringify({
      habit_name: habitName,
      description: 'k6 lifecycle duel',
      duration_days: durationDays,
      opponent_username: opponentUsername,
    }),
    tagOptions(tagName || 'duels_create_directed', token),
  );
}

export function acceptDuel(token, duelId, tagName) {
  return http.post(
    BASE_URL + '/duels/' + duelId + '/accept',
    JSON.stringify({}),
    tagOptions(tagName || 'duels_accept', token),
  );
}

export function checkIn(token, duelId, note, tagName) {
  return http.post(
    BASE_URL + '/duels/' + duelId + '/checkin',
    JSON.stringify({ note: note }),
    tagOptions(tagName || 'duels_checkin', token),
  );
}

export function assertStatus(response, expectedStatus, label) {
  return check(response, {
    [label]: function (r) {
      return r.status === expectedStatus;
    },
  });
}

export function assertJsonField(response, path, label) {
  return check(response, {
    [label]: function (r) {
      return !!r.json(path);
    },
  });
}
