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

-- we now we need to tell Zaapt of the blog and it's settings
INSERT INTO zaapt.model(name, title, module) VALUES('session', 'Session', 'Zaapt::Store::Pg::Session');

-- ----------------------------------------------------------------------------
