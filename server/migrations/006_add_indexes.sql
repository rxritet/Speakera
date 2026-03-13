-- 006_add_indexes.sql
-- Индексы для производительности

CREATE INDEX IF NOT EXISTS idx_duels_creator   ON duels(creator_id);
CREATE INDEX IF NOT EXISTS idx_duels_opponent  ON duels(opponent_id);
CREATE INDEX IF NOT EXISTS idx_duels_status    ON duels(status);
CREATE INDEX IF NOT EXISTS idx_checkins_lookup ON checkins(duel_id, user_id, checked_at);
CREATE INDEX IF NOT EXISTS idx_dp_duel         ON duel_participants(duel_id);
CREATE INDEX IF NOT EXISTS idx_dp_user         ON duel_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_users_wins      ON users(wins DESC);
CREATE INDEX IF NOT EXISTS idx_badges_user     ON badges(user_id);
