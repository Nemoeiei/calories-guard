-- Update Database v6: Adds Notification System
-- This table stores alerts such as "Eating dangerously below minimum calories"

CREATE TABLE IF NOT EXISTS notifications (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Note: To apply this, run it against the Postgres DB:
-- psql -U postgres -d postgres -f update_database_v6_notifications.sql
