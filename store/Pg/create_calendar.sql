-- ----------------------------------------------------------------------------

CREATE SCHEMA calendar;

-- table: calendar
CREATE SEQUENCE calendar.calendar_id_seq;
CREATE TABLE calendar.calendar (
    id              INTEGER NOT NULL DEFAULT nextval('calendar.calendar_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    total           INTEGER NOT NULL DEFAULT 0,
    admin_id        INTEGER NOT NULL REFERENCES account.permission,
    view_id         INTEGER NOT NULL REFERENCES account.permission,
    edit_id         INTEGER NOT NULL REFERENCES account.permission,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER calendar_updated BEFORE UPDATE ON calendar.calendar
    FOR EACH ROW EXECUTE PROCEDURE updated();
COMMENT ON COLUMN calendar.calendar.admin_id IS
    'Admin allows the user to delete the calendar';
COMMENT ON COLUMN calendar.calendar.view_id IS
    'View allows the user to see the calendar and it\'s events';
COMMENT ON COLUMN calendar.calendar.edit_id IS
    'Edit allows the user manipulate the events';

-- table: event
CREATE SEQUENCE calendar.event_id_seq;
CREATE TABLE calendar.event (
    id              INTEGER NOT NULL DEFAULT nextval('calendar.event_id_seq'::TEXT) PRIMARY KEY,
    calendar_id     INTEGER NOT NULL REFERENCES calendar.calendar,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    intro           TEXT NOT NULL,
    description     TEXT NOT NULL,
    startts         TIMESTAMP WITH TIME ZONE NOT NULL,
    endts           TIMESTAMP WITH TIME ZONE NOT NULL,
    allday          BOOLEAN NOT NULL,
    location        TEXT,
    link            TEXT,
    lat             FLOAT,
    lng             FLOAT,
    zoom            INTEGER,

    UNIQUE(calendar_id, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER event_updated BEFORE UPDATE ON calendar.event
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- functions

-- function: event_ai
CREATE OR REPLACE FUNCTION calendar.event_ai() RETURNS trigger as '
    BEGIN
        UPDATE calendar.calendar SET total = total + 1 WHERE id = NEW.calendar_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER event_ai AFTER INSERT ON calendar.event
    FOR EACH ROW EXECUTE PROCEDURE calendar.event_ai();

-- function: event_au
CREATE OR REPLACE FUNCTION calendar.event_au() RETURNS trigger as '
    BEGIN
        IF OLD.calendar_id <> NEW.calendar_id THEN
            UPDATE calendar.calendar SET total = total - 1 WHERE id = OLD.calendar_id;
            UPDATE calendar.calendar SET total = total + 1 WHERE id = NEW.calendar_id;
        END IF;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER event_au BEFORE UPDATE ON calendar.event
    FOR EACH ROW EXECUTE PROCEDURE calendar.event_au();

-- function: event_ad
CREATE OR REPLACE FUNCTION calendar.event_ad() RETURNS trigger as '
    BEGIN
        UPDATE calendar.calendar SET total = total - 1 WHERE id = OLD.calendar_id;
        RETURN NEW;
    END;
' LANGUAGE plpgsql;
CREATE TRIGGER event_ad AFTER DELETE ON calendar.event
    FOR EACH ROW EXECUTE PROCEDURE calendar.event_ad();

-- ----------------------------------------------------------------------------
