-- ----------------------------------------------------------------------------

CREATE SCHEMA blog;

-- table: blog
CREATE SEQUENCE blog.blog_id_seq;
CREATE TABLE blog.blog (
    id              INTEGER NOT NULL DEFAULT nextval('blog.blog_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    show            INTEGER NOT NULL,
    moderate        BOOLEAN NOT NULL DEFAULT False,
    comment         BOOLEAN NOT NULL DEFAULT False,
    trackback       BOOLEAN NOT NULL DEFAULT False,
    admin_id        INTEGER NOT NULL REFERENCES account.permission,
    view_id         INTEGER NOT NULL REFERENCES account.permission,
    edit_id         INTEGER NOT NULL REFERENCES account.permission,
    publish_id      INTEGER NOT NULL REFERENCES account.permission,
    comment_id      INTEGER NOT NULL REFERENCES account.permission,
    trackback_id    INTEGER NOT NULL REFERENCES account.permission,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER blog_updated BEFORE UPDATE ON blog.blog
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN blog.blog.admin_id IS
    'Admin allows the user to do anything with the blog, including delete it';
COMMENT ON COLUMN blog.blog.view_id IS
    'View allows the user to see the blog and it\'s entries';
COMMENT ON COLUMN blog.blog.edit_id IS
    'Edit allows the user manipulate the entries (add/edit/del/labels)';
COMMENT ON COLUMN blog.blog.publish_id IS
    'Publish allows the user to publish or revoke any entries';
COMMENT ON COLUMN blog.blog.comment_id IS
    'Comment allows the user to audit the comments (accept/reject/delete/edit)';
COMMENT ON COLUMN blog.blog.trackback_id IS
    'TrackBack allows the user to audit the trackbacks (accept/reject/delete/edit)';

-- table: entry
CREATE SEQUENCE blog.entry_id_seq;
CREATE TABLE blog.entry (
    id              INTEGER NOT NULL DEFAULT nextval('blog.entry_id_seq'::TEXT) PRIMARY KEY,
    blog_id         INTEGER NOT NULL REFERENCES blog.blog,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    type_id         INTEGER NOT NULL REFERENCES common.type,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    intro           TEXT NOT NULL,
    article         TEXT NOT NULL,
    draft           BOOLEAN DEFAULT False,
    comment         BOOLEAN NOT NULL DEFAULT False,
    trackback       BOOLEAN NOT NULL DEFAULT False,
    comments        INT NOT NULL DEFAULT 0,
    trackbacks      INT NOT NULL DEFAULT 0,

    UNIQUE(blog_id, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER entry_updated BEFORE UPDATE ON blog.entry
    FOR EACH ROW EXECUTE PROCEDURE updated();
CREATE INDEX entry_inserted ON blog.entry(inserted);

-- table: entry_label
CREATE SEQUENCE blog.entry_label_id_seq;
CREATE TABLE blog.entry_label (
    id              INTEGER NOT NULL DEFAULT nextval('blog.entry_label_id_seq'::TEXT) PRIMARY KEY,
    entry_id        INTEGER NOT NULL REFERENCES blog.entry,
    label_id        INTEGER NOT NULL REFERENCES common.label,

    UNIQUE(entry_id, label_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER entry_label_updated BEFORE UPDATE ON blog.entry_label
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: comment
CREATE SEQUENCE blog.comment_id_seq;
CREATE TABLE blog.comment (
    id              INTEGER NOT NULL DEFAULT nextval('blog.comment_id_seq'::TEXT) PRIMARY KEY,
    entry_id        INTEGER NOT NULL REFERENCES blog.entry,
    name            TEXT NOT NULL,
    email           TEXT NOT NULL,
    homepage        TEXT NOT NULL,
    comment         TEXT NOT NULL,
    status          CHAR(3) NOT NULL DEFAULT 'new' CHECK ( status = 'new' OR status = 'acc' OR status = 'rej' ),

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER comment_updated BEFORE UPDATE ON blog.comment
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: trackback
CREATE SEQUENCE blog.trackback_id_seq;
CREATE TABLE blog.trackback (
    id              INTEGER NOT NULL DEFAULT nextval('blog.trackback_id_seq'::TEXT) PRIMARY KEY,
    entry_id        INTEGER NOT NULL REFERENCES blog.entry,
    url             VARCHAR(255) NOT NULL,
    blogname        VARCHAR(255),
    title           VARCHAR(255),
    excerpt         VARCHAR(255),
    status          CHAR(3) NOT NULL DEFAULT 'new' CHECK ( status = 'new' OR status = 'acc' OR status = 'rej' ),

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER trackback_updated BEFORE UPDATE ON blog.trackback
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- functions

-- function: comment_bi
CREATE FUNCTION blog.comment_bi() RETURNS trigger as '
    BEGIN
        IF NEW.status = ''acc'' THEN
            UPDATE blog.entry SET comments = comments + 1 WHERE id = NEW.entry_id;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER comment_ai BEFORE INSERT ON blog.comment
    FOR EACH ROW EXECUTE PROCEDURE blog.comment_bi();

-- function: comment_bu
-- Note: doing this BU since it can then fail, but if we did it AU would it be
-- out of sync? No, I thought not, but if someone knows the correct answer, or
-- indeed whether this even makes a difference, please let me know.
CREATE OR REPLACE FUNCTION blog.comment_bu() RETURNS trigger as '
    BEGIN
        IF OLD.entry_id = NEW.entry_id THEN
            IF OLD.status <> ''acc'' AND NEW.status = ''acc'' THEN
                UPDATE blog.entry SET comments = comments + 1 WHERE id = OLD.entry_id;
            END IF;
            IF OLD.status = ''acc'' AND NEW.status <> ''acc'' THEN
                UPDATE blog.entry SET comments = comments - 1 WHERE id = OLD.entry_id;
            END IF;
        ELSE
            IF OLD.status = ''acc'' THEN
                UPDATE blog.entry SET comments = comments - 1 WHERE id = OLD.entry_id;
            END IF;
            IF NEW.status = ''acc'' THEN
                UPDATE blog.entry SET comments = comments + 1 WHERE id = NEW.entry_id;
            END IF;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER comment_bu BEFORE UPDATE ON blog.comment
    FOR EACH ROW EXECUTE PROCEDURE blog.comment_bu();

-- function: comment_ad
CREATE FUNCTION blog.comment_ad() RETURNS trigger as '
    BEGIN
        IF OLD.status = ''acc'' THEN
            UPDATE blog.entry SET comments = comments - 1 WHERE id = OLD.entry_id;
        END IF;
        RETURN OLD;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER comment_ad BEFORE DELETE ON blog.comment
    FOR EACH ROW EXECUTE PROCEDURE blog.comment_ad();

-- function: trackback_bi
CREATE FUNCTION blog.trackback_bi() RETURNS trigger as '
    BEGIN
        IF NEW.status = ''acc'' THEN
            UPDATE blog.entry SET trackbacks = trackbacks + 1 WHERE id = NEW.entry_id;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER trackback_ai BEFORE INSERT ON blog.trackback
    FOR EACH ROW EXECUTE PROCEDURE blog.trackback_bi();

-- function: trackback_bu
-- Note: doing this BU since it can then fail, but if we did it AU would it be
-- out of sync? No, I thought not, but if someone knows the correct answer, or
-- indeed whether this even makes a difference, please let me know.
CREATE OR REPLACE FUNCTION blog.trackback_bu() RETURNS trigger as '
    BEGIN
        IF OLD.entry_id = NEW.entry_id THEN
            IF OLD.status <> ''acc'' AND NEW.status = ''acc'' THEN
                UPDATE blog.entry SET trackbacks = trackbacks + 1 WHERE id = OLD.entry_id;
            END IF;
            IF OLD.status = ''acc'' AND NEW.status <> ''acc'' THEN
                UPDATE blog.entry SET trackbacks = trackbacks - 1 WHERE id = OLD.entry_id;
            END IF;
        ELSE
            IF OLD.status = ''acc'' THEN
                UPDATE blog.entry SET trackbacks = trackbacks - 1 WHERE id = OLD.entry_id;
            END IF;
            IF NEW.status = ''acc'' THEN
                UPDATE blog.entry SET trackbacks = trackbacks + 1 WHERE id = NEW.entry_id;
            END IF;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER trackback_bu BEFORE UPDATE ON blog.trackback
    FOR EACH ROW EXECUTE PROCEDURE blog.trackback_bu();

-- function: trackback_ad
CREATE FUNCTION blog.trackback_ad() RETURNS trigger as '
    BEGIN
        IF OLD.status = ''acc'' THEN
            UPDATE blog.entry SET trackbacks = trackbacks - 1 WHERE id = OLD.entry_id;
        END IF;
        RETURN OLD;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER trackback_ad BEFORE DELETE ON blog.trackback
    FOR EACH ROW EXECUTE PROCEDURE blog.trackback_ad();

-- ----------------------------------------------------------------------------
