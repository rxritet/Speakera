import http from 'k6/http';
import { check } from 'k6';

export var BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
export var TEST_PASSWORD = __ENV.K6_PASSWORD || 'loadtest123';
export var RUN_ID = __ENV.K6_RUN_ID || String(Date.now());

export function uniqueSuffix() {
  return RUN_ID + '-' + __VU + '-' + __ITER + '-' + Date.now();
}

export function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

export function pick(list) {
  return list[randomInt(0, list.length - 1)];
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

export function tagOptions(tagName, token, extraTags) {
  return {
    headers: jsonHeaders(token),
    tags: Object.assign({ name: tagName }, extraTags || {}),
  };
}

export function createUser(prefix, index) {
  var suffix = typeof index === 'number' ? RUN_ID + '-' + index : uniqueSuffix();
  return {
    username: prefix + '_' + suffix,
    email: prefix + '_' + suffix + '@habitduel.dev',
    password: TEST_PASSWORD,
  };
}

export function registerUser(user, tagName, extraTags) {
  return http.post(
    BASE_URL + '/auth/register',
    JSON.stringify(user),
    tagOptions(tagName || 'auth_register', null, extraTags),
  );
}

export function loginUser(user, tagName, extraTags) {
  return http.post(
    BASE_URL + '/auth/login',
    JSON.stringify({
      email: user.email,
      password: user.password,
    }),
    tagOptions(tagName || 'auth_login', null, extraTags),
  );
}

export function getHealth(tagName, extraTags) {
  return http.get(
    BASE_URL + '/healthz',
    {
      tags: Object.assign({ name: tagName || 'healthz' }, extraTags || {}),
    },
  );
}

export function getCurrentUser(token, tagName, extraTags) {
  return http.get(
    BASE_URL + '/users/me',
    tagOptions(tagName || 'users_me', token, extraTags),
  );
}

export function getLeaderboard(token, tagName, extraTags) {
  return http.get(
    BASE_URL + '/leaderboard/',
    tagOptions(tagName || 'leaderboard', token, extraTags),
  );
}

export function listDuels(token, tagName, extraTags) {
  return http.get(
    BASE_URL + '/duels/',
    tagOptions(tagName || 'duels_list', token, extraTags),
  );
}

export function getDuel(token, duelId, tagName, extraTags) {
  return http.get(
    BASE_URL + '/duels/' + duelId,
    tagOptions(tagName || 'duels_detail', token, extraTags),
  );
}

export function createDirectedDuel(
  token,
  habitName,
  durationDays,
  opponentUsername,
  tagName,
  extraTags,
) {
  return http.post(
    BASE_URL + '/duels/',
    JSON.stringify({
      habit_name: habitName,
      description: 'k6 lifecycle duel',
      duration_days: durationDays,
      opponent_username: opponentUsername,
    }),
    tagOptions(tagName || 'duels_create_directed', token, extraTags),
  );
}

export function acceptDuel(token, duelId, tagName, extraTags) {
  return http.post(
    BASE_URL + '/duels/' + duelId + '/accept',
    JSON.stringify({}),
    tagOptions(tagName || 'duels_accept', token, extraTags),
  );
}

export function checkIn(token, duelId, note, tagName, extraTags) {
  return http.post(
    BASE_URL + '/duels/' + duelId + '/checkin',
    JSON.stringify({ note: note }),
    tagOptions(tagName || 'duels_checkin', token, extraTags),
  );
}

export function registerAndLoginUser(user, registerTag, loginTag, extraTags) {
  var registerResponse = registerUser(user, registerTag, extraTags);
  var registerOk = registerResponse.status === 201 || registerResponse.status === 409;
  check(registerResponse, {
    'register is 201 or 409': function () {
      return registerOk;
    },
  });

  var token = registerResponse.status === 201 ? registerResponse.json('token') : null;
  if (token) {
    return {
      user: user,
      token: token,
      registerStatus: registerResponse.status,
      loginStatus: null,
    };
  }

  var loginResponse = loginUser(user, loginTag, extraTags);
  check(loginResponse, {
    'login is 200': function (r) {
      return r.status === 200;
    },
  });

  return {
    user: user,
    token: loginResponse.status === 200 ? loginResponse.json('token') : null,
    registerStatus: registerResponse.status,
    loginStatus: loginResponse.status,
  };
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
