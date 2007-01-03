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
    admin_id        INTEGER NOT NULL REFERENCES account.role,
    view_id         INTEGER NOT NULL REFERENCES account.role,
    edit_id         INTEGER NOT NULL REFERENCES account.role,
    publish_id      INTEGER NOT NULL REFERENCES account.role,
--    comment_id      INTEGER NOT NULL REFERENCES account.role,
--    trackback_id    INTEGER NOT NULL REFERENCES account.role,

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
    'Entry allows the user manipulate the entries (add/edit/del/tags)';
COMMENT ON COLUMN blog.blog.publish_id IS
    'Publish allows the user to publish or revoke any entries';
-- COMMENT ON COLUMN blog.blog.comment_id IS
--     'Comment allows the user to audit the comments (accept/reject/delete/edit)';
-- COMMENT ON COLUMN blog.blog.trackback_id IS
--     'TrackBack allows the user to audit the trackbacks (accept/reject/delete/edit)';

-- table: entry
CREATE SEQUENCE blog.entry_id_seq;
CREATE TABLE blog.entry (
    id              INTEGER NOT NULL DEFAULT nextval('blog.entry_id_seq'::TEXT) PRIMARY KEY,
    blog_id         INTEGER NOT NULL REFERENCES blog.blog,
    type_id         INTEGER NOT NULL REFERENCES common.type,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    intro           TEXT NOT NULL,
    article         TEXT NOT NULL,
    draft           BOOLEAN DEFAULT False,
    comment         BOOLEAN NOT NULL DEFAULT False,
    trackback       BOOLEAN NOT NULL DEFAULT False,

    UNIQUE(blog_id, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER entry_updated BEFORE UPDATE ON blog.entry
    FOR EACH ROW EXECUTE PROCEDURE updated();
CREATE INDEX entry_inserted ON blog.entry(inserted);

-- table: entry_label
CREATE TABLE blog.entry_label (
    entry_id        INTEGER NOT NULL REFERENCES blog.entry,
    label_id        INTEGER NOT NULL REFERENCES common.label,

    UNIQUE(entry_id, label_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER tag_updated BEFORE UPDATE ON blog.entry_label
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

-- ----------------------------------------------------------------------------
