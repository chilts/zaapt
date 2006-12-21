-- ----------------------------------------------------------------------------

CREATE SCHEMA blog;

-- table: blog
CREATE TABLE blog.blog (
    name            TEXT NOT NULL PRIMARY KEY,
    admin_pid       INTEGER NOT NULL REFERENCES privilege,
    view_pid        INTEGER NOT NULL REFERENCES privilege,
    entry_pid       INTEGER NOT NULL REFERENCES privilege,
    publish_pid     INTEGER NOT NULL REFERENCES privilege,
    comment_pid     INTEGER NOT NULL REFERENCES privilege,
    trackback_pid   INTEGER NOT NULL REFERENCES privilege,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER blog_updated BEFORE UPDATE ON blog.blog
    FOR EACH ROW EXECUTE PROCEDURE updated();
COMMENT ON COLUMN blog.blog.admin_pid IS
    'Admin allows the user to do anything with the blog, including delete it';
COMMENT ON COLUMN blog.blog.view_pid IS
    'View allows the user to see the blog and it\'s entries';
COMMENT ON COLUMN blog.blog.entry_pid IS
    'Entry allows the user manipulate the entries (add/edit/del/tags)';
COMMENT ON COLUMN blog.blog.publish_pid IS
    'Publish allows the user to publish or revoke any entries';
COMMENT ON COLUMN blog.blog.comment_pid IS
    'Comment allows the user to audit the comments (accept/reject/delete/edit)';
COMMENT ON COLUMN blog.blog.trackback_pid IS
    'TrackBack allows the user to audit the trackbacks (accept/reject/delete/edit)';

-- table: entry
CREATE SEQUENCE blog.entry_id_seq;
CREATE TABLE blog.entry (
    id              INTEGER NOT NULL DEFAULT nextval('blog.entry_id_seq'::TEXT) PRIMARY KEY,
    blog_name       TEXT NOT NULL REFERENCES blog.blog,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    intro           TEXT NOT NULL,
    article         TEXT NOT NULL,
    draft           BOOLEAN DEFAULT False,

    UNIQUE(blog_name, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER entry_updated BEFORE UPDATE ON blog.entry
    FOR EACH ROW EXECUTE PROCEDURE updated();
CREATE INDEX entry_inserted ON blog.entry(inserted);

-- table: tag
CREATE TABLE blog.tag (
    name            TEXT NOT NULL PRIMARY KEY,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER tag_updated BEFORE UPDATE ON blog.tag
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: entry
CREATE SEQUENCE blog.entry_tag_id_seq;
CREATE TABLE blog.entry_tag (
    id              INTEGER NOT NULL DEFAULT nextval('blog.entry_tag_id_seq'::TEXT) PRIMARY KEY,
    entry_id        INTEGER NOT NULL REFERENCES blog.entry,
    tag_name        TEXT NOT NULL REFERENCES blog.tag,

    UNIQUE(entry_id, tag_name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER tag_updated BEFORE UPDATE ON blog.entry_tag
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
    blogname        VARCHAR(255) NOT NULL DEFAULT '',
    title           VARCHAR(255) NOT NULL DEFAULT '',
    excerpt         VARCHAR(255) NOT NULL DEFAULT '',
    status          CHAR(3) NOT NULL DEFAULT 'new' CHECK ( status = 'new' OR status = 'acc' OR status = 'rej' ),

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER trackback_updated BEFORE UPDATE ON blog.trackback
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- ----------------------------------------------------------------------------
