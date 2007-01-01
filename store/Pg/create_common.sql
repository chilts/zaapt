-- ----------------------------------------------------------------------------

CREATE SCHEMA common;

-- table: type
CREATE SEQUENCE common.type_id_seq;
CREATE TABLE common.type (
    id              INTEGER NOT NULL DEFAULT nextval('common.type_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER type_updated BEFORE UPDATE ON common.type
    FOR EACH ROW EXECUTE PROCEDURE updated();
INSERT INTO common.type(name) VALUES('html');
INSERT INTO common.type(name) VALUES('text');
INSERT INTO common.type(name) VALUES('code');

-- ----------------------------------------------------------------------------
