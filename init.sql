DROP TABLE IF EXISTS channel_post_media CASCADE;
DROP TABLE IF EXISTS channel_posts CASCADE;
DROP TABLE IF EXISTS channel_subscribers CASCADE;
DROP TABLE IF EXISTS channels CASCADE;
DROP TABLE IF EXISTS group_message_media CASCADE;
DROP TABLE IF EXISTS group_messages CASCADE;
DROP TABLE IF EXISTS group_members CASCADE;
DROP TABLE IF EXISTS groups CASCADE;
DROP TABLE IF EXISTS story_media CASCADE;
DROP TABLE IF EXISTS stories CASCADE;
DROP TABLE IF EXISTS media_files CASCADE;
DROP TABLE IF EXISTS media_types CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    user_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    display_name VARCHAR(100) NOT NULL,
    bio TEXT,
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    CONSTRAINT chk_users_status
        CHECK (status IN ('active', 'deleted', 'banned'))
);

CREATE TABLE user_settings (
    user_id BIGINT PRIMARY KEY,
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    allow_calls BOOLEAN NOT NULL DEFAULT TRUE,
    allow_invites BOOLEAN NOT NULL DEFAULT TRUE,
    theme_name VARCHAR(30) NOT NULL DEFAULT 'system',
    language_code VARCHAR(10) NOT NULL DEFAULT 'ru',
    last_seen_visible BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_user_settings_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE media_types (
    media_type_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    type_name VARCHAR(30) NOT NULL UNIQUE,
    file_extension VARCHAR(10) NOT NULL,
    mime_type VARCHAR(100) NOT NULL
);

CREATE TABLE media_files (
    media_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_user_id BIGINT NOT NULL,
    media_type_id BIGINT NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes > 0),
    duration_seconds INT CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    uploaded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_media_owner
        FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
    CONSTRAINT fk_media_type
        FOREIGN KEY (media_type_id) REFERENCES media_types(media_type_id)
);

CREATE TABLE stories (
    story_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    author_user_id BIGINT NOT NULL,
    caption VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    privacy_level VARCHAR(20) NOT NULL DEFAULT 'contacts',
    CONSTRAINT fk_story_author
        FOREIGN KEY (author_user_id) REFERENCES users(user_id),
    CONSTRAINT chk_story_privacy
        CHECK (privacy_level IN ('public', 'contacts', 'close_friends')),
    CONSTRAINT chk_story_expiration
        CHECK (expires_at > created_at)
);

CREATE TABLE story_media (
    story_id BIGINT NOT NULL,
    media_id BIGINT NOT NULL,
    PRIMARY KEY (story_id, media_id),
    CONSTRAINT fk_story_media_story
        FOREIGN KEY (story_id) REFERENCES stories(story_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_story_media_file
        FOREIGN KEY (media_id) REFERENCES media_files(media_id)
);

CREATE TABLE groups (
    group_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    owner_user_id BIGINT NOT NULL,
    description VARCHAR(255),
    privacy_type VARCHAR(20) NOT NULL DEFAULT 'private',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_group_owner
        FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
    CONSTRAINT chk_group_privacy
        CHECK (privacy_type IN ('public', 'private'))
);

CREATE TABLE group_members (
    group_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    role_name VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id),
    CONSTRAINT fk_group_members_group
        FOREIGN KEY (group_id) REFERENCES groups(group_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_group_members_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_group_member_role
        CHECK (role_name IN ('owner', 'admin', 'member'))
);

CREATE TABLE group_messages (
    group_message_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    group_id BIGINT NOT NULL,
    author_user_id BIGINT,
    message_text TEXT NOT NULL,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reply_to_message_id BIGINT,
    CONSTRAINT fk_group_message_group
        FOREIGN KEY (group_id) REFERENCES groups(group_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_group_message_author
        FOREIGN KEY (author_user_id) REFERENCES users(user_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_group_message_reply
        FOREIGN KEY (reply_to_message_id) REFERENCES group_messages(group_message_id)
);

CREATE TABLE group_message_media (
    group_message_id BIGINT NOT NULL,
    media_id BIGINT NOT NULL,
    PRIMARY KEY (group_message_id, media_id),
    CONSTRAINT fk_group_message_media_message
        FOREIGN KEY (group_message_id) REFERENCES group_messages(group_message_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_group_message_media_file
        FOREIGN KEY (media_id) REFERENCES media_files(media_id)
);

CREATE TABLE channels (
    channel_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    owner_user_id BIGINT NOT NULL,
    description VARCHAR(255),
    channel_type VARCHAR(20) NOT NULL DEFAULT 'public',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_channel_owner
        FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
    CONSTRAINT chk_channel_type
        CHECK (channel_type IN ('public', 'private'))
);

CREATE TABLE channel_subscribers (
    channel_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    subscribed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (channel_id, user_id),
    CONSTRAINT fk_channel_subscriber_channel
        FOREIGN KEY (channel_id) REFERENCES channels(channel_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_channel_subscriber_user
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON DELETE CASCADE
);

CREATE TABLE channel_posts (
    post_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    channel_id BIGINT NOT NULL,
    author_user_id BIGINT,
    post_text TEXT NOT NULL,
    published_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_channel_post_channel
        FOREIGN KEY (channel_id) REFERENCES channels(channel_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_channel_post_author
        FOREIGN KEY (author_user_id) REFERENCES users(user_id)
        ON DELETE SET NULL
);

CREATE TABLE channel_post_media (
    post_id BIGINT NOT NULL,
    media_id BIGINT NOT NULL,
    PRIMARY KEY (post_id, media_id),
    CONSTRAINT fk_channel_post_media_post
        FOREIGN KEY (post_id) REFERENCES channel_posts(post_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_channel_post_media_file
        FOREIGN KEY (media_id) REFERENCES media_files(media_id)
);

INSERT INTO users (username, phone_number, display_name, bio, status) VALUES
('ivanov', '+79990000001', 'Иван Иванов', 'Люблю чаты и каналы', 'active'),
('petrova', '+79990000002', 'Анна Петрова', 'Пишу новости', 'active'),
('sidorov', '+79990000003', 'Олег Сидоров', 'Смотрю истории и медиа', 'active');

INSERT INTO user_settings (user_id, is_private, allow_calls, allow_invites, theme_name, language_code, last_seen_visible) VALUES
(1, FALSE, TRUE, TRUE, 'dark', 'ru', TRUE),
(2, TRUE, TRUE, FALSE, 'light', 'ru', FALSE),
(3, FALSE, FALSE, TRUE, 'system', 'en', TRUE);

INSERT INTO media_types (type_name, file_extension, mime_type) VALUES
('image', 'jpg', 'image/jpeg'),
('video', 'mp4', 'video/mp4'),
('audio', 'mp3', 'audio/mpeg'),
('document', 'pdf', 'application/pdf');

INSERT INTO media_files (owner_user_id, media_type_id, file_name, file_size_bytes, duration_seconds) VALUES
(1, 1, 'story_photo.jpg', 1250000, NULL),
(2, 2, 'group_clip.mp4', 8450000, 34),
(2, 4, 'schedule.pdf', 420000, NULL);

INSERT INTO stories (author_user_id, caption, created_at, expires_at, privacy_level) VALUES
(1, 'Доброе утро!', '2026-03-24 09:00:00', '2026-03-25 09:00:00', 'contacts'),
(3, 'Новая фотография', '2026-03-24 10:00:00', '2026-03-25 10:00:00', 'public');

INSERT INTO story_media (story_id, media_id) VALUES
(1, 1),
(2, 1);

INSERT INTO groups (title, owner_user_id, description, privacy_type) VALUES
('Учебная группа', 1, 'Группа для обсуждения лабораторных работ', 'private');

INSERT INTO group_members (group_id, user_id, role_name) VALUES
(1, 1, 'owner'),
(1, 2, 'admin'),
(1, 3, 'member');

INSERT INTO group_messages (group_id, author_user_id, message_text) VALUES
(1, 1, 'Всем привет! Здесь будем обсуждать проект.'),
(1, 2, 'Я загрузила видео с пояснениями.');

INSERT INTO group_message_media (group_message_id, media_id) VALUES
(2, 2);

INSERT INTO channels (title, owner_user_id, description, channel_type) VALUES
('Новости кафедры', 2, 'Официальный канал с объявлениями', 'public');

INSERT INTO channel_subscribers (channel_id, user_id, notification_enabled) VALUES
(1, 1, TRUE),
(1, 2, TRUE),
(1, 3, FALSE);

INSERT INTO channel_posts (channel_id, author_user_id, post_text) VALUES
(1, 2, 'Опубликовано новое расписание на следующую неделю.');

INSERT INTO channel_post_media (post_id, media_id) VALUES
(1, 3);
