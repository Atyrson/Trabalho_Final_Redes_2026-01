CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    login TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'client')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS videos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    hd_path TEXT NOT NULL,
    ld_path TEXT NOT NULL,
    description TEXT,
    duration_seconds INTEGER,
    bitrate INTEGER,
    resolution TEXT,
    video_codec TEXT,
    audio_codec TEXT
);

CREATE TABLE IF NOT EXISTS channels (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    number INTEGER NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    current_video_id INTEGER REFERENCES videos(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel_id INTEGER NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    profile TEXT NOT NULL CHECK (profile IN ('LAN', 'WAN115K')),
    multicast_address TEXT NOT NULL,
    last_seen TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    active INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS active_streams (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    channel_id INTEGER NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    profile TEXT NOT NULL CHECK (profile IN ('LAN', 'WAN115K')),
    multicast_address TEXT NOT NULL,
    port INTEGER NOT NULL DEFAULT 5004,
    pid INTEGER NOT NULL,
    started_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sessions_active_profile ON sessions(active, profile);
CREATE INDEX IF NOT EXISTS idx_sessions_channel_profile ON sessions(channel_id, profile, active);
CREATE INDEX IF NOT EXISTS idx_active_streams_profile_channel ON active_streams(profile, channel_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_channels_number ON channels(number);
CREATE UNIQUE INDEX IF NOT EXISTS idx_stream_unique_profile_channel ON active_streams(profile, channel_id);
