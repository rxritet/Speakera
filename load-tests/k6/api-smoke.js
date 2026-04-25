import { sleep } from 'k6';
import {
  assertStatus,
  createDirectedDuel,
  createUser,
  getCurrentUser,
  getLeaderboard,
  listDuels,
  loginUser,
  registerUser,
} from './common.js';

export var options = {
  vus: Number(__ENV.K6_VUS || 5),
  duration: __ENV.K6_DURATION || '15s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  var creator = createUser('smoke');

  var registerResponse = registerUser(creator, 'smoke_register');
  if (!assertStatus(registerResponse, 201, 'smoke register status is 201')) {
    sleep(1);
    return;
  }

  var loginResponse = loginUser(creator, 'smoke_login');
  if (!assertStatus(loginResponse, 200, 'smoke login status is 200')) {
    sleep(1);
    return;
  }

  var token = loginResponse.json('token');

  assertStatus(getCurrentUser(token, 'smoke_me'), 200, 'smoke users me status is 200');
  assertStatus(listDuels(token, 'smoke_duels_list'), 200, 'smoke duel list status is 200');
  assertStatus(getLeaderboard(token, 'smoke_leaderboard'), 200, 'smoke leaderboard status is 200');

  var opponent = createUser('smoke_opp');
  var opponentRegister = registerUser(opponent, 'smoke_register_opponent');
  assertStatus(opponentRegister, 201, 'smoke opponent register status is 201');

  var duelResponse = createDirectedDuel(
    token,
    'Smoke Habit',
    7,
    opponent.username,
    'smoke_duel_create',
  );
  assertStatus(duelResponse, 201, 'smoke duel create status is 201');

  sleep(1);
}
