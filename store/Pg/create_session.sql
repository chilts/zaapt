-- ----------------------------------------------------------------------------

CREATE SCHEMA session;

-- table: session
CREATE TABLE session.session (
    id              CHAR(32) NOT NULL PRIMARY KEY,
    a_session       TEXT,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER session_updated BEFORE UPDATE ON session.session
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- ----------------------------------------------------------------------------
