-- EuromillonesApi Database Schema
-- PostgreSQL Database Setup

-- Create database (run as superuser)
-- CREATE DATABASE euromillones_db;
-- GRANT ALL PRIVILEGES ON DATABASE euromillones_db TO your_username;

-- Connect to the database and run the following:

-- Enable UUID extension (optional, for future use)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Table: users
-- Stores user information with unique email constraint
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: combinations
-- Stores user lottery combinations with JSON format for numbers
CREATE TABLE combinations (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    balls JSON NOT NULL,
    stars JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure no duplicate combinations per user
    UNIQUE(user_id, balls, stars)
);

-- Table: results
-- Stores lottery results with date as unique identifier
CREATE TABLE results (
    id SERIAL PRIMARY KEY,
    date DATE UNIQUE NOT NULL,
    bolas JSON NOT NULL,
    stars JSON NOT NULL,
    jackpot JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: credentials
-- Stores API access credentials for authenticated users
CREATE TABLE credentials (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_combinations_user_id ON combinations(user_id);
CREATE INDEX idx_results_date ON results(date);
CREATE INDEX idx_credentials_nickname ON credentials(nickname);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers to automatically update updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_combinations_updated_at 
    BEFORE UPDATE ON combinations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_results_updated_at
    BEFORE UPDATE ON results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_credentials_updated_at
    BEFORE UPDATE ON credentials
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sample data for testing (optional)
INSERT INTO users (email) VALUES 
    ('test@example.com'),
    ('admin@euromillions.com'),
    ('user1@test.com');

INSERT INTO combinations (user_id, balls, stars) VALUES 
    (1, '[1, 12, 23, 34, 45]', '[3, 8]'),
    (1, '[7, 18, 29, 40, 50]', '[1, 11]'),
    (2, '[5, 15, 25, 35, 47]', '[2, 9]');

INSERT INTO results (date, bolas, stars, jackpot) VALUES
    ('2024-01-15', '[7, 23, 34, 42, 48]', '[3, 8]', '{"5": {"2": "15000000.00", "1": "250000.00", "0": "50000.00"}, "4": {"2": "5000.00", "1": "500.00", "0": "100.00"}}'),
    ('2024-01-12', '[12, 19, 31, 44, 49]', '[4, 10]', '{"5": {"2": "12000000.00", "1": "200000.00", "0": "45000.00"}, "4": {"2": "4500.00", "1": "450.00", "0": "90.00"}}');

-- Production credentials (example, hashed password))
INSERT INTO credentials (nickname, password_hash) VALUES

-- Views for common queries (optional)
CREATE VIEW user_combinations AS
SELECT 
    u.email,
    u.id as user_id,
    c.id as combination_id,
    c.balls,
    c.stars,
    c.created_at
FROM users u
JOIN combinations c ON u.id = c.user_id
ORDER BY u.email, c.created_at;

CREATE VIEW recent_results AS
SELECT 
    date,
    bolas as balls,
    stars,
    jackpot,
    created_at
FROM results
ORDER BY date DESC
LIMIT 10;

-- Grant permissions (adjust username as needed)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO your_username;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO your_username;

-- Display table information
\d+ users;
\d+ combinations;
\d+ results;
\d+ credentials;

-- Show sample data
SELECT 'Users:' as table_name;
SELECT * FROM users;

SELECT 'Combinations:' as table_name;
SELECT * FROM user_combinations;

SELECT 'Results:' as table_name;
SELECT * FROM recent_results;

SELECT 'Credentials:' as table_name;
SELECT id, nickname, created_at FROM credentials;