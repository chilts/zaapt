-- ----------------------------------------------------------------------------

CREATE SCHEMA forum;

-- table: forum
CREATE SEQUENCE forum.forum_id_seq;
CREATE TABLE forum.forum (
    id              INTEGER NOT NULL DEFAULT nextval('forum.forum_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    show            INTEGER NOT NULL,
    topics          INTEGER NOT NULL DEFAULT 0,
    posts           INTEGER NOT NULL DEFAULT 0,
    poster_id       INTEGER REFERENCES account.account,
    admin_id        INTEGER NOT NULL REFERENCES account.role,
    view_id         INTEGER NOT NULL REFERENCES account.role,
    moderator_id    INTEGER NOT NULL REFERENCES account.role,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER forum_updated BEFORE UPDATE ON forum.forum
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN forum.forum.topics IS
    'Shows the number of topics in this forum';
COMMENT ON COLUMN forum.forum.posts IS
    'Shows the number of posts in this forum';
COMMENT ON COLUMN forum.forum.admin_id IS
    'Admin allows the user to delete it(self)';
COMMENT ON COLUMN forum.forum.view_id IS
    'View allows the user to see the forum details';

-- table: topic
CREATE SEQUENCE forum.topic_id_seq;
CREATE TABLE forum.topic (
    id              INTEGER NOT NULL DEFAULT nextval('forum.topic_id_seq'::TEXT) PRIMARY KEY,
    forum_id        INTEGER NOT NULL REFERENCES forum.forum,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    subject         VARCHAR(255) NOT NULL,
    sticky          BOOLEAN NOT NULL DEFAULT False,
    locked          BOOLEAN NOT NULL DEFAULT False,
    posts           INTEGER NOT NULL DEFAULT 0,
    poster_id       INTEGER NOT NULL REFERENCES account.account,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER topic_updated BEFORE UPDATE ON forum.topic
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN forum.topic.posts IS
    'Shows the number of posts in this topic';

-- table: post
CREATE SEQUENCE forum.post_id_seq;
CREATE TABLE forum.post (
    id              INTEGER NOT NULL DEFAULT nextval('forum.post_id_seq'::TEXT) PRIMARY KEY,
    topic_id        INTEGER NOT NULL REFERENCES forum.topic,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    message         TEXT NOT NULL,
    type_id         INTEGER NOT NULL REFERENCES common.type,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER post_updated BEFORE UPDATE ON forum.post
    FOR EACH ROW EXECUTE PROCEDURE updated();
CREATE INDEX post_inserted ON forum.post(inserted);

-- table: info
CREATE TABLE forum.info (
    account_id      INTEGER NOT NULL REFERENCES account.account PRIMARY KEY,
    posts           INTEGER NOT NULL DEFAULT 0,
    signature       TEXT NOT NULL DEFAULT '',

    LIKE base       INCLUDING DEFAULTS
);

-- functions

-- function: newtopic
CREATE FUNCTION forum.newtopic() RETURNS trigger as '
    BEGIN
        UPDATE forum.forum SET topics = topics + 1 WHERE id = NEW.forum_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER newtopic_inserted BEFORE INSERT ON forum.topic
    FOR EACH ROW EXECUTE PROCEDURE forum.newtopic();

-- function: deltopic
CREATE FUNCTION forum.deltopic() RETURNS trigger as '
    BEGIN
        UPDATE forum.forum SET topics = topics - 1 WHERE id = OLD.forum_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER deltopic_deleted AFTER DELETE ON forum.topic
    FOR EACH ROW EXECUTE PROCEDURE forum.deltopic();

-- function: newpost
CREATE FUNCTION forum.newpost() RETURNS trigger as '
    DECLARE
        -- to hold the account id of the person posting
        found_id INTEGER;
    BEGIN
        UPDATE forum.topic SET posts = posts + 1, poster_id = NEW.account_id WHERE id = NEW.topic_id;
        UPDATE forum.forum SET posts = posts + 1, poster_id = NEW.account_id WHERE id = (SELECT forum_id FROM forum.topic WHERE id = NEW.topic_id);

        -- now update this users number of posts
        SELECT INTO found_id account_id FROM forum.info WHERE account_id = NEW.account_id;
        IF NOT FOUND THEN
            INSERT INTO forum.info(account_id) VALUES(NEW.account_id);
            SELECT INTO found_id account_id FROM forum.info WHERE account_id = NEW.account_id;
        END IF;
        UPDATE forum.info SET posts = posts + 1 WHERE account_id = found_id;

        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER newpost_inserted BEFORE INSERT ON forum.post
    FOR EACH ROW EXECUTE PROCEDURE forum.newpost();

-- function: delpost
CREATE FUNCTION forum.delpost() RETURNS trigger as '
    BEGIN
        UPDATE forum.topic SET posts = posts - 1 WHERE id = OLD.topic_id;
        UPDATE forum.forum SET posts = posts - 1 WHERE id = (SELECT forum_id FROM forum.topic WHERE id = OLD.topic_id);
        UPDATE forum.info SET posts = posts - 1 WHERE account_id = OLD.account_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER delpost_deleted AFTER DELETE ON forum.post
    FOR EACH ROW EXECUTE PROCEDURE forum.delpost();

-- ----------------------------------------------------------------------------
