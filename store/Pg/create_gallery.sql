-- ----------------------------------------------------------------------------

CREATE SCHEMA gallery;

-- table: gallery
CREATE SEQUENCE gallery.gallery_id_seq;
CREATE TABLE gallery.gallery (
    id              INTEGER NOT NULL DEFAULT nextval('gallery.gallery_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    path            TEXT NOT NULL,
    original        TEXT NOT NULL,
    webdir          TEXT NOT NULL,
    show            INTEGER NOT NULL,
    extractexif     BOOLEAN NOT NULL DEFAULT False,
    total           INTEGER NOT NULL DEFAULT 0,
    admin_id        INTEGER NOT NULL REFERENCES account.permission,
    view_id         INTEGER NOT NULL REFERENCES account.permission,
    edit_id         INTEGER NOT NULL REFERENCES account.permission,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER gallery_updated BEFORE UPDATE ON gallery.gallery
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN gallery.gallery.admin_id IS
    'Admin allows the user to delete the gallery';
COMMENT ON COLUMN gallery.gallery.view_id IS
    'View allows the user to see the gallery and it\'s pictures';
COMMENT ON COLUMN gallery.gallery.edit_id IS
    'Edit allows the user manipulate the entries (upload/del)';

-- table: picture
CREATE SEQUENCE gallery.picture_id_seq;
CREATE TABLE gallery.picture (
    id              INTEGER NOT NULL DEFAULT nextval('gallery.picture_id_seq'::TEXT) PRIMARY KEY,
    gallery_id      INTEGER NOT NULL REFERENCES gallery.gallery,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    filename        TEXT NOT NULL,

    UNIQUE(gallery_id, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER picture_updated BEFORE UPDATE ON gallery.picture
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: field
CREATE SEQUENCE gallery.field_id_seq;
CREATE TABLE gallery.field (
    id              INTEGER NOT NULL DEFAULT nextval('gallery.field_id_seq'::TEXT) PRIMARY KEY,
    info            TEXT NOT NULL,
    description     TEXT NOT NULL,
    isexif          BOOLEAN NOT NULL DEFAULT False,

    UNIQUE(info, isexif),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER field_updated BEFORE UPDATE ON gallery.field
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: detail
CREATE SEQUENCE gallery.detail_id_seq;
CREATE TABLE gallery.detail (
    id              INTEGER NOT NULL DEFAULT nextval('gallery.detail_id_seq'::TEXT) PRIMARY KEY,
    picture_id      INTEGER NOT NULL REFERENCES gallery.picture,
    field_id        INTEGER NOT NULL REFERENCES gallery.field,
    value           TEXT NOT NULL,

    UNIQUE(picture_id, field_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER detail_updated BEFORE UPDATE ON gallery.detail
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: size
CREATE SEQUENCE gallery.size_id_seq;
CREATE TABLE gallery.size (
    id              INTEGER NOT NULL DEFAULT nextval('gallery.size_id_seq'::TEXT) PRIMARY KEY,
    gallery_id      INTEGER NOT NULL REFERENCES gallery.gallery,
    size            INTEGER NOT NULL,
    path            TEXT NOT NULL,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER size_updated BEFORE UPDATE ON gallery.size
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: required
CREATE SEQUENCE gallery.required_id_seq;
CREATE TABLE gallery.required (
    id              INTEGER NOT NULL DEFAULT nextval('gallery.required_id_seq'::TEXT) PRIMARY KEY,
    gallery_id      INTEGER NOT NULL REFERENCES gallery.gallery,
    field_id        INTEGER NOT NULL REFERENCES gallery.field,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER required_updated BEFORE UPDATE ON gallery.required
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- functions

-- function: picture_ai
CREATE FUNCTION gallery.picture_ai() RETURNS trigger as '
    BEGIN
        UPDATE gallery.gallery SET total = total + 1 WHERE id = NEW.gallery_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER picture_ai AFTER INSERT ON gallery.picture
    FOR EACH ROW EXECUTE PROCEDURE gallery.picture_ai();

-- function: picture_au
CREATE OR REPLACE FUNCTION gallery.picture_au() RETURNS trigger as '
    BEGIN
        IF OLD.gallery_id <> NEW.gallery_id THEN
            UPDATE gallery.gallery SET total = total - 1 WHERE id = OLD.gallery_id;
            UPDATE gallery.gallery SET total = total + 1 WHERE id = NEW.gallery_id;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER picture_au BEFORE UPDATE ON gallery.picture
    FOR EACH ROW EXECUTE PROCEDURE gallery.picture_au();

-- function: picture_ad
CREATE OR REPLACE FUNCTION gallery.picture_ad() RETURNS trigger as '
    BEGIN
        UPDATE gallery.gallery SET total = total - 1 WHERE id = OLD.gallery_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER picture_ad AFTER DELETE ON gallery.picture
    FOR EACH ROW EXECUTE PROCEDURE gallery.picture_ad();

-- ----------------------------------------------------------------------------
