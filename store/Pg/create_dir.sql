-- ----------------------------------------------------------------------------

CREATE SCHEMA dir;

-- table: dir
CREATE SEQUENCE dir.dir_id_seq;
CREATE TABLE dir.dir (
    id              INTEGER NOT NULL DEFAULT nextval('dir.dir_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    path            TEXT NOT NULL,
    webdir          TEXT NOT NULL,
    total           INTEGER NOT NULL DEFAULT 0,
    admin_id        INTEGER NOT NULL REFERENCES account.permission,
    view_id         INTEGER NOT NULL REFERENCES account.permission,
    edit_id         INTEGER NOT NULL REFERENCES account.permission,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER dir_updated BEFORE UPDATE ON dir.dir
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN dir.dir.admin_id IS
    'Admin allows the user to delete the dir';
COMMENT ON COLUMN dir.dir.view_id IS
    'View allows the user to see the dir and it\'s files';
COMMENT ON COLUMN dir.dir.edit_id IS
    'Edit allows the user manipulate the entries (upload/del)';

-- table: file
CREATE SEQUENCE dir.file_id_seq;
CREATE TABLE dir.file (
    id              INTEGER NOT NULL DEFAULT nextval('dir.file_id_seq'::TEXT) PRIMARY KEY,
    dir_id          INTEGER NOT NULL REFERENCES dir.dir,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    ext             TEXT NOT NULL,
    filename        TEXT NOT NULL,

    UNIQUE(dir_id, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER file_updated BEFORE UPDATE ON dir.file
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- functions

-- function: file_ai
CREATE FUNCTION dir.file_ai() RETURNS trigger as '
    BEGIN
        UPDATE dir.dir SET total = total + 1 WHERE id = NEW.dir_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER file_ai AFTER INSERT ON dir.file
    FOR EACH ROW EXECUTE PROCEDURE dir.file_ai();

-- function: file_au
CREATE OR REPLACE FUNCTION dir.file_au() RETURNS trigger as '
    BEGIN
        IF OLD.dir_id <> NEW.dir_id THEN
            UPDATE dir.dir SET total = total - 1 WHERE id = OLD.dir_id;
            UPDATE dir.dir SET total = total + 1 WHERE id = NEW.dir_id;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER file_au BEFORE UPDATE ON dir.file
    FOR EACH ROW EXECUTE PROCEDURE dir.file_au();

-- function: file_ad
CREATE OR REPLACE FUNCTION dir.file_ad() RETURNS trigger as '
    BEGIN
        UPDATE dir.dir SET total = total - 1 WHERE id = OLD.dir_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER file_ad AFTER DELETE ON dir.file
    FOR EACH ROW EXECUTE PROCEDURE dir.file_ad();

-- ----------------------------------------------------------------------------
