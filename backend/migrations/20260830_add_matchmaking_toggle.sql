UPDATE users SET matchmaking = 0 WHERE matchmaking IS NULL;
ALTER TABLE users
MODIFY COLUMN matchmaking INT NOT NULL DEFAULT 0;
