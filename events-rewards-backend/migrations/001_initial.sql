
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    selfie_path VARCHAR(500),
    voice_path VARCHAR(500),
    device_id VARCHAR(255),
    device_info JSONB,
    location JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Events table
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(500),
    max_participants INTEGER,
    current_participants INTEGER DEFAULT 0,
    banner_image VARCHAR(500),
    category VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event registrations table
CREATE TABLE IF NOT EXISTS event_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    event_id UUID REFERENCES events(id),
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) DEFAULT 'registered',
    UNIQUE(user_id, event_id)
);

-- News table
CREATE TABLE IF NOT EXISTS news (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    summary VARCHAR(500),
    image_url VARCHAR(500),
    category VARCHAR(100),
    is_published BOOLEAN DEFAULT FALSE,
    publish_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- UI Configuration table
CREATE TABLE IF NOT EXISTS ui_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    config_type VARCHAR(100) NOT NULL,
    config_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Rewards table
CREATE TABLE IF NOT EXISTS rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    reward_type VARCHAR(100),
    value DECIMAL(10,2),
    probability DECIMAL(5,4) NOT NULL CHECK (probability >= 0.0001 AND probability <= 1.0000),
    total_available INTEGER,
    total_claimed INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User rewards table 
CREATE TABLE IF NOT EXISTS user_rewards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    reward_id UUID REFERENCES rewards(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),  
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),  
    claimed_at TIMESTAMP WITH TIME ZONE,                
    status VARCHAR(50) DEFAULT 'pending',
    claim_code VARCHAR(100),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Spin attempts table (for rate limiting)
CREATE TABLE IF NOT EXISTS spin_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    attempt_date DATE NOT NULL,
    attempts_count INTEGER DEFAULT 1,
    last_attempt TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, attempt_date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_device_id ON users(device_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON events(event_date);
CREATE INDEX IF NOT EXISTS idx_events_category ON events(category);
CREATE INDEX IF NOT EXISTS idx_events_active ON events(is_active);
CREATE INDEX IF NOT EXISTS idx_event_registrations_user ON event_registrations(user_id);
CREATE INDEX IF NOT EXISTS idx_event_registrations_event ON event_registrations(event_id);
CREATE INDEX IF NOT EXISTS idx_news_published ON news(is_published, publish_date);
CREATE INDEX IF NOT EXISTS idx_ui_configs_user ON ui_configs(user_id, config_type);
CREATE INDEX IF NOT EXISTS idx_rewards_active ON rewards(is_active, probability);

CREATE INDEX IF NOT EXISTS idx_user_rewards_user ON user_rewards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_rewards_status ON user_rewards(status);
CREATE INDEX IF NOT EXISTS idx_user_rewards_created_at ON user_rewards(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_rewards_claim_code ON user_rewards(claim_code) WHERE claim_code IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_rewards_expires_at ON user_rewards(expires_at) WHERE expires_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_spin_attempts_user_date ON spin_attempts(user_id, attempt_date);

-- Insert default rewards (only if table is empty)
INSERT INTO rewards (name, description, reward_type, value, probability, total_available)
SELECT name, description, reward_type, value, probability, total_available
FROM (VALUES
    ('Better Luck Next Time', 'No reward this time', 'none', 0, 0.4000, 999999),
    ('10 Points', 'Get 10 bonus points', 'points', 10, 0.3000, 1000),
    ('20 Points', 'Get 20 bonus points', 'points', 20, 0.1500, 500),
    ('50 Points', 'Get 50 bonus points', 'points', 50, 0.0800, 200),
    ('100 Points', 'Get 100 bonus points', 'points', 100, 0.0400, 100),
    ('5% Discount', 'Get 5% discount on next purchase', 'discount', 5, 0.0200, 50),
    ('10% Discount', 'Get 10% discount on next purchase', 'discount', 10, 0.0080, 30),
    ('Free Coffee', 'Get a free coffee voucher', 'product', 0, 0.0015, 15),
    ('Free T-Shirt', 'Get a free branded t-shirt', 'product', 0, 0.0004, 5),
    ('Grand Prize', 'Win the grand prize!', 'product', 0, 0.0001, 1)
) AS default_rewards(name, description, reward_type, value, probability, total_available)
WHERE NOT EXISTS (SELECT 1 FROM rewards LIMIT 1);

-- Insert default UI configurations (only if table is empty)  
INSERT INTO ui_configs (user_id, config_type, config_data) VALUES
(NULL, 'default_home', '{
  "modules": [
    {"type": "banner", "enabled": true, "order": 1},
    {"type": "events", "enabled": true, "order": 2, "limit": 5},
    {"type": "news", "enabled": true, "order": 3, "limit": 3},
    {"type": "lucky_draw", "enabled": true, "order": 4}
  ],
  "theme": {
    "primary_color": "#6366f1",
    "secondary_color": "#f59e0b"
  }
}'::jsonb),
(NULL, 'default_events', '{
  "filters": ["date", "category", "location"],
  "sort_options": ["date", "popularity", "title"],
  "display_mode": "grid"
}'::jsonb)
ON CONFLICT DO NOTHING;

-- Create a function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at (idempotent)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_users_updated_at') THEN
        CREATE TRIGGER update_users_updated_at
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_events_updated_at') THEN
        CREATE TRIGGER update_events_updated_at
        BEFORE UPDATE ON events
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_news_updated_at') THEN
        CREATE TRIGGER update_news_updated_at
        BEFORE UPDATE ON news
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_ui_configs_updated_at') THEN
        CREATE TRIGGER update_ui_configs_updated_at
        BEFORE UPDATE ON ui_configs
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_rewards_updated_at') THEN
        CREATE TRIGGER update_rewards_updated_at
        BEFORE UPDATE ON rewards
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;

    -- ADDED: Trigger for user_rewards table
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_user_rewards_updated_at') THEN
        CREATE TRIGGER update_user_rewards_updated_at
        BEFORE UPDATE ON user_rewards
        FOR EACH ROW
        EXECUTE FUNCTION update_updated_at_column();
    END IF;
END
$$;

-- ADDED: Create constraint to ensure proper status transitions
DO $$
BEGIN
    -- Add check constraint for valid statuses if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'user_rewards_status_check' 
        AND conrelid = 'user_rewards'::regclass
    ) THEN
        ALTER TABLE user_rewards 
        ADD CONSTRAINT user_rewards_status_check 
        CHECK (status IN ('pending', 'claimed', 'expired'));
    END IF;
END
$$;

COMMIT;
