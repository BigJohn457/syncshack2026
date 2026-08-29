ALTER TABLE meetup_participants
MODIFY COLUMN attendance_status
ENUM('joined', 'attended', 'finished', 'no_show', 'left', 'cancelled')
NULL DEFAULT 'joined';
