-- ----------------------------------------------------------------------------

CREATE SCHEMA account;

-- table: account
CREATE SEQUENCE account.account_id_seq;
CREATE TABLE account.account (
    id              INTEGER NOT NULL DEFAULT nextval('account.account_id_seq'::TEXT) PRIMARY KEY,
    username        TEXT NOT NULL,
    firstname       TEXT NOT NULL,
    lastname        TEXT NOT NULL,
    email           TEXT NOT NULL,
    notify          BOOLEAN NOT NULL DEFAULT False,
    salt            VARCHAR(8) NOT NULL,
    password        VARCHAR(32) NOT NULL,
    confirmed       BOOLEAN NOT NULL DEFAULT False,
    admin           BOOLEAN NOT NULL DEFAULT False,
    logins          INTEGER NOT NULL DEFAULT 0,
    last            TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(username),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER account_updated BEFORE UPDATE ON account.account
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- Some information from the following links:
-- - http://en.wikipedia.org/wiki/Role-Based_Access_Control
-- - http://www.ecs.syr.edu/faculty/chin/cse774/readings/rbac/p34-ferraiolo.pdf
--   (specifically, P.42, Fig.2

-- table: role
CREATE SEQUENCE account.role_id_seq;
CREATE TABLE account.role (
    id              INTEGER NOT NULL DEFAULT nextval('account.role_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT NOT NULL,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER role_updated BEFORE UPDATE ON account.role
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: permission
CREATE SEQUENCE account.permission_id_seq;
CREATE TABLE account.permission (
    id              INTEGER NOT NULL DEFAULT nextval('account.permission_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT NOT NULL,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER permission_updated BEFORE UPDATE ON account.permission
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: ra - role assignment (read: which account has which role)
-- Note: in most RBAC articles, this is named the 'user assignment' table)
CREATE SEQUENCE account.ra_id_seq;
CREATE TABLE account.ra (
    id              INTEGER NOT NULL DEFAULT nextval('account.ra_id_seq'::TEXT) PRIMARY KEY,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    role_id         INTEGER NOT NULL REFERENCES account.role,

    UNIQUE(account_id, role_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER required_updated BEFORE UPDATE ON account.ra
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: pa - permission assignment (read: which role has which permission)
CREATE SEQUENCE account.pa_id_seq;
CREATE TABLE account.pa (
    id              INTEGER NOT NULL DEFAULT nextval('account.pa_id_seq'::TEXT) PRIMARY KEY,
    role_id         INTEGER NOT NULL REFERENCES account.role,
    permission_id   INTEGER NOT NULL REFERENCES account.permission,

    UNIQUE(role_id, permission_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER required_updated BEFORE UPDATE ON account.pa
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: rh - role hierarchy (read: which roles encompass other roles)
-- ToDo: for the future, to fulfil Level 2 - Hierarchical RBAC
-- CREATE SEQUENCE account.rh_id_seq;
-- CREATE TABLE account.rh (
--     id              INTEGER NOT NULL DEFAULT nextval('account.rh_id_seq'::TEXT) PRIMARY KEY,
--     role_id         INTEGER NOT NULL REFERENCES account.role,
--     role_id         INTEGER NOT NULL REFERENCES account.role,
-- 
--     LIKE base       INCLUDING DEFAULTS
-- );
-- CREATE TRIGGER required_updated BEFORE UPDATE ON account.rh
--     FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: ssd - static separation of duty
-- if a (role, role) pair is in this list, it means they can't be assigned to the same account
-- ToDo: for the future
-- CREATE SEQUENCE account.ssd_id_seq;
-- CREATE TABLE account.ssd (
--     id              INTEGER NOT NULL DEFAULT nextval('account.ssd_id_seq'::TEXT) PRIMARY KEY,
--     role_id         INTEGER NOT NULL REFERENCES account.role,
--     role_id         INTEGER NOT NULL REFERENCES account.role,
-- 
--     LIKE base       INCLUDING DEFAULTS
-- );
-- CREATE TRIGGER required_updated BEFORE UPDATE ON account.ssd
--     FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: confirm
CREATE TABLE account.confirm (
    account_id      INTEGER NOT NULL REFERENCES account.account PRIMARY KEY,
    code            VARCHAR(32) NOT NULL,
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER confirm_updated BEFORE UPDATE ON account.confirm
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: invitation
CREATE SEQUENCE account.invitation_id_seq;
CREATE TABLE account.invitation (
    id              INTEGER NOT NULL DEFAULT nextval('account.invitation_id_seq'::TEXT) PRIMARY KEY,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    name            TEXT NOT NULL DEFAULT '',
    email           TEXT NOT NULL,

    UNIQUE(email),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER invitation_updated BEFORE UPDATE ON account.invitation
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: token
CREATE SEQUENCE account.token_id_seq;
CREATE TABLE account.token (
    id              INTEGER NOT NULL DEFAULT nextval('account.token_id_seq'::TEXT) PRIMARY KEY,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    code            VARCHAR(32) NOT NULL,

    UNIQUE(code),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER token_updated BEFORE UPDATE ON account.token
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: email
CREATE SEQUENCE account..email_id_seq;
CREATE TABLE account.email (
    id              INTEGER NOT NULL DEFAULT nextval('account.email_id_seq'::TEXT) PRIMARY KEY,
    subject         TEXT NOT NULL,
    text            TEXT NOT NULL,
    html            TEXT NOT NULL,
    type_id         INTEGER NOT NULL REFERENCES common.type,
    isbulk          BOOLEAN NOT NULL,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER email_updated BEFORE UPDATE ON account.email
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: recipient
CREATE SEQUENCE account.recipient_id_seq;
CREATE TABLE account.recipient (
    id              INTEGER NOT NULL DEFAULT nextval('account.recipient_id_seq'::TEXT) PRIMARY KEY,
    email_id        INTEGER NOT NULL REFERENCES account.email,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    issent          BOOLEAN NOT NULL DEFAULT False,
    iserror         BOOLEAN NOT NULL DEFAULT False,
    error           TEXT NOT NULL DEFAULT '',

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER recipient_updated BEFORE UPDATE ON account.recipient
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: info (info about each user: token, rejected)
CREATE SEQUENCE account.info_id_seq;
CREATE TABLE account.info (
    account_id      INTEGER NOT NULL REFERENCES account.account PRIMARY KEY,
    token           VARCHAR(32) NOT NULL,
    sent            INTEGER NOT NULL DEFAULT 0,
    failed          INTEGER NOT NULL DEFAULT 0,

    UNIQUE(token),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER info_updated BEFORE UPDATE ON account.info
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- we now we need to tell Zaapt of the blog and it's settings
INSERT INTO zaapt.model(name, title, module) VALUES('account', 'Account', 'Zaapt::Store::Pg::Account');

-- settings
INSERT INTO
    zaapt.setting(model_id, name, value)
VALUES (
    (SELECT id FROM zaapt.model WHERE name = 'account'),
    'location',
    ''
);        

-- ----------------------------------------------------------------------------
