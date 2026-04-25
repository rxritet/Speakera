import { sleep } from 'k6';
import {
  assertStatus,
  createDirectedDuel,
  createUser,
  getDuel,
  listDuels,
  loginUser,
  registerUser,
  acceptDuel,
  checkIn,
} from './common.js';

export var options = {
  vus: Number(__ENV.K6_VUS || 10),
  duration: __ENV.K6_DURATION || '20s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
    'http_req_duration{name:duels_create_directed}': ['p(95)<700'],
    'http_req_duration{name:duels_accept}': ['p(95)<700'],
    'http_req_duration{name:duels_checkin_creator}': ['p(95)<700'],
    'http_req_duration{name:duels_checkin_opponent}': ['p(95)<700'],
    'http_req_duration{name:duels_detail_creator}': ['p(95)<700'],
    'http_req_duration{name:duels_detail_opponent}': ['p(95)<700'],
  },
};

export default function () {
  var creator = createUser('life_creator');
  var opponent = createUser('life_opponent');

  var creatorRegister = registerUser(creator, 'life_register_creator');
  var opponentRegister = registerUser(opponent, 'life_register_opponent');

  if (!assertStatus(creatorRegister, 201, 'lifecycle creator register is 201')) {
    sleep(1);
    return;
  }
  if (!assertStatus(opponentRegister, 201, 'lifecycle opponent register is 201')) {
    sleep(1);
    return;
  }

  var creatorLogin = loginUser(creator, 'life_login_creator');
  var opponentLogin = loginUser(opponent, 'life_login_opponent');

  if (!assertStatus(creatorLogin, 200, 'lifecycle creator login is 200')) {
    sleep(1);
    return;
  }
  if (!assertStatus(opponentLogin, 200, 'lifecycle opponent login is 200')) {
    sleep(1);
    return;
  }

  var creatorToken = creatorLogin.json('token');
  var opponentToken = opponentLogin.json('token');

  var duelResponse = createDirectedDuel(
    creatorToken,
    'Lifecycle Habit',
    7,
    opponent.username,
    'duels_create_directed',
  );
  if (!assertStatus(duelResponse, 201, 'lifecycle duel create is 201')) {
    sleep(1);
    return;
  }

  var duelId = duelResponse.json('id');

  assertStatus(acceptDuel(opponentToken, duelId, 'duels_accept'), 200, 'lifecycle duel accept is 200');
  assertStatus(listDuels(creatorToken, 'life_list_creator'), 200, 'lifecycle creator duel list is 200');
  assertStatus(listDuels(opponentToken, 'life_list_opponent'), 200, 'lifecycle opponent duel list is 200');
  assertStatus(
    checkIn(creatorToken, duelId, 'creator lifecycle check-in', 'duels_checkin_creator'),
    201,
    'lifecycle creator checkin is 201',
  );
  assertStatus(
    checkIn(opponentToken, duelId, 'opponent lifecycle check-in', 'duels_checkin_opponent'),
    201,
    'lifecycle opponent checkin is 201',
  );
  assertStatus(getDuel(creatorToken, duelId, 'duels_detail_creator'), 200, 'lifecycle creator detail is 200');
  assertStatus(getDuel(opponentToken, duelId, 'duels_detail_opponent'), 200, 'lifecycle opponent detail is 200');

  sleep(1);
}
