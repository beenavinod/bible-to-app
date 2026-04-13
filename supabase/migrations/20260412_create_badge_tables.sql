-- =============================================================================
-- Badge system tables: badge_definitions (catalog) + user_badges (earned)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. badge_definitions — read-only catalog of all earnable badges
-- ---------------------------------------------------------------------------

CREATE TABLE badge_definitions (
    id              smallserial     PRIMARY KEY,
    slug            text            NOT NULL UNIQUE,
    name            text            NOT NULL,
    description     text            NOT NULL,
    type            text            NOT NULL
                        CHECK (type IN ('task-streak', 'verse-share', 'first-share')),
    actions_required int            NOT NULL CHECK (actions_required > 0),
    weight          int             NOT NULL DEFAULT 0,
    is_active       boolean         NOT NULL DEFAULT true,
    created_at      timestamptz     NOT NULL DEFAULT now()
);

COMMENT ON TABLE  badge_definitions IS 'Static catalog of all achievement badges. Managed via migrations only.';
COMMENT ON COLUMN badge_definitions.slug IS 'Stable identifier used in API and Swift code, e.g. task_streak_7';
COMMENT ON COLUMN badge_definitions.type IS 'Badge category: task-streak | verse-share | first-share';
COMMENT ON COLUMN badge_definitions.actions_required IS 'Threshold to earn: streak days, share count, or 1 for one-time actions';
COMMENT ON COLUMN badge_definitions.weight IS 'Display/prestige ordering weight (higher = more prestigious)';

-- ---------------------------------------------------------------------------
-- 2. user_badges — one row per user per earned badge (permanent, no revoke)
-- ---------------------------------------------------------------------------

CREATE TABLE user_badges (
    id                      uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id                 uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    badge_definition_id     smallint    NOT NULL REFERENCES badge_definitions(id),
    earned_at               timestamptz NOT NULL DEFAULT now(),

    UNIQUE (user_id, badge_definition_id)
);

COMMENT ON TABLE  user_badges IS 'Earned badges per user. Rows are permanent — no update or delete allowed via client.';
COMMENT ON COLUMN user_badges.earned_at IS 'Server-side timestamp of when the badge was awarded.';

CREATE INDEX idx_user_badges_user_id ON user_badges (user_id);

-- ---------------------------------------------------------------------------
-- 3. Row Level Security
-- ---------------------------------------------------------------------------

ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read badge definitions"
    ON badge_definitions FOR SELECT
    TO authenticated
    USING (true);

ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own badges"
    ON user_badges FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own badges"
    ON user_badges FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

-- No UPDATE or DELETE policies — badges are permanent

-- ---------------------------------------------------------------------------
-- 4. Seed data — task-streak badges (20 milestones)
-- ---------------------------------------------------------------------------

INSERT INTO badge_definitions (slug, name, description, type, actions_required, weight) VALUES
    ('task_streak_1',   'First Step',   'The journey begins',               'task-streak', 1,   1),
    ('task_streak_2',   'Ignition',     'You showed up again',              'task-streak', 2,   3),
    ('task_streak_3',   'Spark',        'Momentum is building',             'task-streak', 3,   5),
    ('task_streak_5',   'Rise',         'Growth has started',               'task-streak', 5,   8),
    ('task_streak_7',   'Momentum',     'One week strong',                  'task-streak', 7,   12),
    ('task_streak_10',  'Rooted',       'Stability is forming',             'task-streak', 10,  16),
    ('task_streak_14',  'On Track',     'You are finding direction',        'task-streak', 14,  20),
    ('task_streak_21',  'Steady',       'Consistency is real',              'task-streak', 21,  28),
    ('task_streak_30',  'Climbing',     'A full month achieved',            'task-streak', 30,  36),
    ('task_streak_45',  'Aligned',      'You''re in rhythm',               'task-streak', 45,  48),
    ('task_streak_60',  'Breakthrough', 'Habit becomes lifestyle',          'task-streak', 60,  60),
    ('task_streak_75',  'Unstoppable',  'You refuse to quit',              'task-streak', 75,  75),
    ('task_streak_90',  'Renewed',      'Transformation is happening',      'task-streak', 90,  90),
    ('task_streak_105', 'Radiant',      'Your light is visible',           'task-streak', 105, 105),
    ('task_streak_120', 'Deep Rooted',  'Strong and grounded',             'task-streak', 120, 120),
    ('task_streak_150', 'Ascending',    'Next-level commitment',           'task-streak', 150, 140),
    ('task_streak_180', 'Unwavering',   'Long-term discipline proven',      'task-streak', 180, 165),
    ('task_streak_210', 'Devoted',      'Fully committed path',            'task-streak', 210, 185),
    ('task_streak_300', 'Mastery',      'Elite consistency',               'task-streak', 300, 240),
    ('task_streak_365', '365',          'A year of unwavering faith',      'task-streak', 365, 300);

-- ---------------------------------------------------------------------------
-- 5. Seed data — verse-share badges
-- ---------------------------------------------------------------------------

INSERT INTO badge_definitions (slug, name, description, type, actions_required, weight) VALUES
    ('verse_share_3', 'Word Spreader', 'Shared God''s word 3 times', 'verse-share', 3, 15);

-- ---------------------------------------------------------------------------
-- 6. Seed data — first-share badges
-- ---------------------------------------------------------------------------

INSERT INTO badge_definitions (slug, name, description, type, actions_required, weight) VALUES
    ('first_share', 'First Light', 'Shared a verse for the first time', 'first-share', 1, 10);

-- ---------------------------------------------------------------------------
-- 7. Seed data — first-login badge
-- ---------------------------------------------------------------------------

INSERT INTO badge_definitions (slug, name, description, type, actions_required, weight) VALUES
    ('first_login', 'Begin with Faith', 'Started the journey of faith', 'first-login', 1, 2);
