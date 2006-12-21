-- ----------------------------------------------------------------------------

CREATE SCHEMA content;

-- table: group
CREATE SEQUENCE content.content_id_seq;
CREATE TABLE content.content (
    id              INTEGER NOT NULL DEFAULT nextval('content.content_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    admin_id        INTEGER NOT NULL REFERENCES account.role,
    view_id         INTEGER NOT NULL REFERENCES account.role,
    edit_id         INTEGER NOT NULL REFERENCES account.role,
    publish_id      INTEGER NOT NULL REFERENCES account.role,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER content_updated BEFORE UPDATE ON content.content
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN content.content.admin_id IS
    'Admin allows the user to do anything with the content, including delete it';
COMMENT ON COLUMN content.content.view_id IS
    'View allows the user to see the content and it\'s pages';
COMMENT ON COLUMN content.content.edit_id IS
    'Entry allows the user manipulate the pages (add/edit/del)';
COMMENT ON COLUMN content.content.publish_id IS
    'Publish allows the user to (un)publish entries';

-- table: type
CREATE SEQUENCE content.type_id_seq;
CREATE TABLE content.type (
    id              INTEGER NOT NULL DEFAULT nextval('content.type_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER type_updated BEFORE UPDATE ON content.type
    FOR EACH ROW EXECUTE PROCEDURE updated();
INSERT INTO content.type(name) VALUES('html');
INSERT INTO content.type(name) VALUES('text');
INSERT INTO content.type(name) VALUES('code');

-- table: page
CREATE SEQUENCE content.page_id_seq;
CREATE TABLE content.page (
    id              INTEGER NOT NULL DEFAULT nextval('content.page_id_seq'::TEXT) PRIMARY KEY,
    content_id      INTEGER NOT NULL REFERENCES content.content,
    type_id         INTEGER NOT NULL REFERENCES content.type,
    name            TEXT NOT NULL,
    content         TEXT NOT NULL,

    UNIQUE(name, content_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER page_updated BEFORE UPDATE ON content.page
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- ----------------------------------------------------------------------------
