import http from 'k6/http';
import { check, sleep } from 'k6';

import {
  BASE_URL,
  RUN_ID,
  acceptDuel,
  assertStatus,
  checkIn,
  createDirectedDuel,
  createUser,
  getCurrentUser,
  getDuel,
  getHealth,
  getLeaderboard,
  jsonHeaders,
  listDuels,
  registerAndLoginUser,
} from './common.js';

var authVus = Number(__ENV.K6_AUTH_VUS || 8);
var duelVus = Number(__ENV.K6_DUEL_VUS || 20);
var browseRate = Number(__ENV.K6_BROWSE_RATE || 25);
var browseVus = Number(__ENV.K6_BROWSE_VUS || 40);
var rampUp = __ENV.K6_RAMP_UP || '1m';
var steady = __ENV.K6_STEADY || '4m';
var rampDown = __ENV.K6_RAMP_DOWN || '1m';
var pairCount = Number(__ENV.K6_PAIR_COUNT || Math.max(duelVus * 3, 60));

export var options = {
  discardResponseBodies: false,
  scenarios: {
    auth_churn: {
      executor: 'ramping-vus',
      exec: 'authChurn',
      startVUs: 1,
      stages: [
        { duration: rampUp, target: authVus },
        { duration: steady, target: authVus },
        { duration: rampDown, target: 0 },
      ],
      gracefulRampDown: '10s',
    },
    duel_lifecycle: {
      executor: 'ramping-vus',
      exec: 'duelLifecycle',
      startVUs: 1,
      stages: [
        { duration: rampUp, target: duelVus },
        { duration: steady, target: duelVus },
        { duration: rampDown, target: 0 },
      ],
      gracefulRampDown: '15s',
    },
    browse_api: {
      executor: 'constant-arrival-rate',
      exec: 'browseApi',
      rate: browseRate,
      timeUnit: '1s',
      duration: totalDuration(),
      preAllocatedVUs: browseVus,
      maxVUs: browseVus * 2,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.03'],
    http_req_duration: ['p(95)<1200', 'p(99)<2500'],
    'http_req_duration{name:healthz}': ['p(95)<300'],
    'http_req_duration{name:auth_register_dynamic}': ['p(95)<600'],
    'http_req_duration{name:auth_login_dynamic}': ['p(95)<600'],
    'http_req_duration{name:users_me_browse}': ['p(95)<700'],
    'http_req_duration{name:duels_create_lifecycle}': ['p(95)<900'],
    'http_req_duration{name:duels_accept_lifecycle}': ['p(95)<900'],
    'http_req_duration{name:duels_checkin_creator}': ['p(95)<900'],
    'http_req_duration{name:duels_checkin_opponent}': ['p(95)<900'],
    'http_req_duration{name:duels_detail_lifecycle_creator}': ['p(95)<900'],
    'http_req_duration{name:duels_detail_lifecycle_opponent}': ['p(95)<900'],
    'http_req_duration{name:duels_list_browse}': ['p(95)<800'],
    'http_req_duration{name:leaderboard_browse}': ['p(95)<700'],
  },
};

export function setup() {
  var seededPairs = [];

  for (var i = 0; i < pairCount; i += 1) {
    var creator = createUser('seed_creator', i * 2);
    var opponent = createUser('seed_opponent', i * 2 + 1);

    var creatorSession = registerAndLoginUser(
      creator,
      'auth_register_seed_creator',
      'auth_login_seed_creator',
      { phase: 'setup' },
    );
    var opponentSession = registerAndLoginUser(
      opponent,
      'auth_register_seed_opponent',
      'auth_login_seed_opponent',
      { phase: 'setup' },
    );

    if (creatorSession.token && opponentSession.token) {
      seededPairs.push({
        creator: creatorSession.user,
        creatorToken: creatorSession.token,
        opponent: opponentSession.user,
        opponentToken: opponentSession.token,
      });
    }
  }

  return {
    runId: RUN_ID,
    pairs: seededPairs,
  };
}

export function authChurn() {
  var user = createUser('dynamic');
  var healthResponse = getHealth('healthz', { scenario: 'auth_churn' });
  assertStatus(healthResponse, 200, 'healthz is 200 in auth churn');

  var session = registerAndLoginUser(
    user,
    'auth_register_dynamic',
    'auth_login_dynamic',
    { scenario: 'auth_churn' },
  );
  if (!session.token) {
    sleep(1);
    return;
  }

  assertStatus(
    getCurrentUser(session.token, 'users_me_auth', { scenario: 'auth_churn' }),
    200,
    'users me is 200 in auth churn',
  );
  assertStatus(
    getLeaderboard(session.token, 'leaderboard_auth', { scenario: 'auth_churn' }),
    200,
    'leaderboard is 200 in auth churn',
  );

  sleep(Math.random() * 2 + 1);
}

export function duelLifecycle(data) {
  if (!data.pairs || data.pairs.length === 0) {
    sleep(1);
    return;
  }

  var pair = data.pairs[(__VU + __ITER) % data.pairs.length];
  var habitName = 'k6 duel ' + data.runId + ' ' + __VU + '-' + __ITER;

  assertStatus(
    getHealth('healthz', { scenario: 'duel_lifecycle' }),
    200,
    'healthz is 200 in duel lifecycle',
  );
  assertStatus(
    getCurrentUser(
      pair.creatorToken,
      'users_me_lifecycle_creator',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'creator users me is 200',
  );
  assertStatus(
    getCurrentUser(
      pair.opponentToken,
      'users_me_lifecycle_opponent',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'opponent users me is 200',
  );

  var duelResponse = createDirectedDuel(
    pair.creatorToken,
    habitName,
    7,
    pair.opponent.username,
    'duels_create_lifecycle',
    { scenario: 'duel_lifecycle' },
  );
  if (!assertStatus(duelResponse, 201, 'lifecycle duel create is 201')) {
    sleep(1);
    return;
  }

  var duelId = duelResponse.json('id');
  check(duelResponse, {
    'lifecycle duel create returns id': function (r) {
      return !!r.json('id');
    },
  });

  assertStatus(
    acceptDuel(
      pair.opponentToken,
      duelId,
      'duels_accept_lifecycle',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'lifecycle duel accept is 200',
  );

  assertStatus(
    listDuels(
      pair.creatorToken,
      'duels_list_lifecycle_creator',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'lifecycle creator duels list is 200',
  );
  assertStatus(
    listDuels(
      pair.opponentToken,
      'duels_list_lifecycle_opponent',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'lifecycle opponent duels list is 200',
  );

  assertStatus(
    checkIn(
      pair.creatorToken,
      duelId,
      'creator lifecycle check-in',
      'duels_checkin_creator',
      { scenario: 'duel_lifecycle' },
    ),
    201,
    'creator checkin is 201',
  );
  assertStatus(
    checkIn(
      pair.opponentToken,
      duelId,
      'opponent lifecycle check-in',
      'duels_checkin_opponent',
      { scenario: 'duel_lifecycle' },
    ),
    201,
    'opponent checkin is 201',
  );

  assertStatus(
    getDuel(
      pair.creatorToken,
      duelId,
      'duels_detail_lifecycle_creator',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'creator duel detail is 200',
  );
  assertStatus(
    getDuel(
      pair.opponentToken,
      duelId,
      'duels_detail_lifecycle_opponent',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'opponent duel detail is 200',
  );
  assertStatus(
    getLeaderboard(
      pair.creatorToken,
      'leaderboard_lifecycle',
      { scenario: 'duel_lifecycle' },
    ),
    200,
    'leaderboard is 200 in lifecycle',
  );

  sleep(Math.random() * 2 + 0.5);
}

export function browseApi(data) {
  if (!data.pairs || data.pairs.length === 0) {
    sleep(1);
    return;
  }

  var pair = data.pairs[(__VU + __ITER) % data.pairs.length];
  var token = __ITER % 2 === 0 ? pair.creatorToken : pair.opponentToken;

  var batchResponses = http.batch([
    ['GET', BASE_URL + '/healthz', null, { tags: { name: 'healthz', scenario: 'browse_api' } }],
    [
      'GET',
      BASE_URL + '/users/me',
      null,
      {
        headers: jsonHeaders(token),
        tags: { name: 'users_me_browse', scenario: 'browse_api' },
      },
    ],
    [
      'GET',
      BASE_URL + '/duels/',
      null,
      {
        headers: jsonHeaders(token),
        tags: { name: 'duels_list_browse', scenario: 'browse_api' },
      },
    ],
    [
      'GET',
      BASE_URL + '/leaderboard/',
      null,
      {
        headers: jsonHeaders(token),
        tags: { name: 'leaderboard_browse', scenario: 'browse_api' },
      },
    ],
  ]);

  check(batchResponses[0], {
    'browse healthz is 200': function (r) {
      return r.status === 200;
    },
  });
  check(batchResponses[1], {
    'browse users me is 200': function (r) {
      return r.status === 200;
    },
  });
  check(batchResponses[2], {
    'browse duels list is 200': function (r) {
      return r.status === 200;
    },
  });
  check(batchResponses[3], {
    'browse leaderboard is 200': function (r) {
      return r.status === 200;
    },
  });

  var duelList = [];
  if (batchResponses[2].status === 200) {
    duelList = batchResponses[2].json('duels') || [];
  }

  if (duelList.length > 0) {
    var duel = duelList[randomIndex(duelList.length)];
    if (duel && duel.id) {
      assertStatus(
        getDuel(
          token,
          duel.id,
          'duels_detail_browse',
          { scenario: 'browse_api' },
        ),
        200,
        'browse duel detail is 200',
      );
    }
  }

  sleep(Math.random() * 1.5 + 0.25);
}

export default function (data) {
  duelLifecycle(data);
}

function totalDuration() {
  return sumDurations([rampUp, steady, rampDown]);
}

function sumDurations(parts) {
  var totalSeconds = 0;

  for (var i = 0; i < parts.length; i += 1) {
    totalSeconds += parseDurationToSeconds(parts[i]);
  }

  return totalSeconds + 's';
}

function parseDurationToSeconds(value) {
  var match = String(value).trim().match(/^(\d+)(ms|s|m|h)$/);
  if (!match) {
    return 60;
  }

  var amount = Number(match[1]);
  var unit = match[2];

  if (unit === 'ms') {
    return Math.max(1, Math.ceil(amount / 1000));
  }
  if (unit === 's') {
    return amount;
  }
  if (unit === 'm') {
    return amount * 60;
  }
  if (unit === 'h') {
    return amount * 3600;
  }

  return 60;
}

function randomIndex(length) {
  return Math.floor(Math.random() * length);
}
