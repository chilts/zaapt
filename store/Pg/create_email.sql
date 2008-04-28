-- ----------------------------------------------------------------------------

CREATE SCHEMA email;

-- table: email
CREATE SEQUENCE email.email_id_seq;
CREATE TABLE email.email (
    id              INTEGER NOT NULL DEFAULT nextval('email.email_id_seq'::TEXT) PRIMARY KEY,
    subject         TEXT NOT NULL,
    text            TEXT NOT NULL,
    html            TEXT NOT NULL,
    type_id         INTEGER NOT NULL REFERENCES common.type,
    isbulk          BOOLEAN NOT NULL,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER email_updated BEFORE UPDATE ON email.email
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: recipient
CREATE SEQUENCE email.recipient_id_seq;
CREATE TABLE email.recipient (
    id              INTEGER NOT NULL DEFAULT nextval('email.recipient_id_seq'::TEXT) PRIMARY KEY,
    email_id        INTEGER NOT NULL REFERENCES email.email,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    issent          BOOLEAN NOT NULL DEFAULT False,
    iserror         BOOLEAN NOT NULL DEFAULT False,
    error           TEXT NOT NULL DEFAULT '',

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER recipient_updated BEFORE UPDATE ON email.recipient
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: info (info about each user: token, rejected)
CREATE SEQUENCE email.info_id_seq;
CREATE TABLE email.info (
    account_id      INTEGER NOT NULL REFERENCES account.account PRIMARY KEY,
    token           VARCHAR(32) NOT NULL,
    numsent         INTEGER NOT NULL DEFAULT 0,
    numfailed       INTEGER NOT NULL DEFAULT 0,

    UNIQUE(token),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER info_updated BEFORE UPDATE ON email.info
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- we now we need to tell Zaapt of the blog and it's settings
INSERT INTO zaapt.model(name, title, module) VALUES('email', 'Email', 'Zaapt::Store::Pg::Email');

-- ----------------------------------------------------------------------------
