import { sleep } from 'k6';
import {
  assertJsonField,
  assertStatus,
  createDirectedDuel,
  createUser,
  getCurrentUser,
  getDuel,
  getLeaderboard,
  listDuels,
  loginUser,
  registerUser,
  acceptDuel,
  checkIn,
} from './common.js';

var vus = Number(__ENV.K6_VUS || 20);
var duration = __ENV.K6_DURATION || '30s';

export var options = {
  vus: vus,
  duration: duration,
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<800', 'p(99)<1500'],
    'http_req_duration{name:auth_register_creator}': ['p(95)<400'],
    'http_req_duration{name:auth_login_creator}': ['p(95)<400'],
    'http_req_duration{name:duels_create_directed}': ['p(95)<700'],
    'http_req_duration{name:duels_accept}': ['p(95)<700'],
    'http_req_duration{name:duels_checkin}': ['p(95)<700'],
    'http_req_duration{name:duels_detail_creator}': ['p(95)<700'],
    'http_req_duration{name:leaderboard}': ['p(95)<500'],
  },
};

export default function () {
  var creator = createUser('creator');
  var opponent = createUser('opponent');

  var creatorRegister = registerUser(creator, 'auth_register_creator');
  assertStatus(creatorRegister, 201, 'creator register status is 201');
  assertJsonField(creatorRegister, 'token', 'creator register returns token');

  var opponentRegister = registerUser(opponent, 'auth_register_opponent');
  assertStatus(opponentRegister, 201, 'opponent register status is 201');
  assertJsonField(opponentRegister, 'token', 'opponent register returns token');

  var creatorLogin = loginUser(creator, 'auth_login_creator');
  if (!assertStatus(creatorLogin, 200, 'creator login status is 200')) {
    sleep(1);
    return;
  }
  var creatorToken = creatorLogin.json('token');

  var opponentLogin = loginUser(opponent, 'auth_login_opponent');
  if (!assertStatus(opponentLogin, 200, 'opponent login status is 200')) {
    sleep(1);
    return;
  }
  var opponentToken = opponentLogin.json('token');

  var meResponse = getCurrentUser(creatorToken, 'users_me_creator');
  assertStatus(meResponse, 200, 'users me status is 200');

  var duelResponse = createDirectedDuel(
    creatorToken,
    'Load Test Habit',
    7,
    opponent.username,
    'duels_create_directed',
  );
  if (!assertStatus(duelResponse, 201, 'create directed duel status is 201')) {
    sleep(1);
    return;
  }

  var duelId = duelResponse.json('id');
  assertJsonField(duelResponse, 'id', 'create directed duel returns id');

  var acceptResponse = acceptDuel(opponentToken, duelId, 'duels_accept');
  assertStatus(acceptResponse, 200, 'accept duel status is 200');

  var creatorList = listDuels(creatorToken, 'duels_list_creator');
  assertStatus(creatorList, 200, 'creator duel list status is 200');

  var opponentList = listDuels(opponentToken, 'duels_list_opponent');
  assertStatus(opponentList, 200, 'opponent duel list status is 200');

  var creatorCheckin = checkIn(
    creatorToken,
    duelId,
    'creator check-in from k6',
    'duels_checkin',
  );
  assertStatus(creatorCheckin, 201, 'creator checkin status is 201');

  var creatorDetail = getDuel(creatorToken, duelId, 'duels_detail_creator');
  assertStatus(creatorDetail, 200, 'creator duel detail status is 200');

  var opponentDetail = getDuel(opponentToken, duelId, 'duels_detail_opponent');
  assertStatus(opponentDetail, 200, 'opponent duel detail status is 200');

  var leaderboardResponse = getLeaderboard(creatorToken, 'leaderboard');
  assertStatus(leaderboardResponse, 200, 'leaderboard status is 200');

  sleep(1);
}
