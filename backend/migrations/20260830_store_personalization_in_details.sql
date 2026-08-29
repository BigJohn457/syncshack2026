UPDATE users
SET details = personalization_answers
WHERE personalization_answers IS NOT NULL;

ALTER TABLE users
DROP COLUMN personalization_answers;
