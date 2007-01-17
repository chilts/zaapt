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

    UNIQUE(username),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER account_updated BEFORE UPDATE ON account.account
    FOR EACH ROW EXECUTE PROCEDURE updated();

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

-- table: privilege
CREATE TABLE account.privilege (
    account_id      INTEGER NOT NULL REFERENCES account.account,
    role_id         INTEGER NOT NULL REFERENCES account.role,

    UNIQUE(account_id, role_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER privilege_updated BEFORE UPDATE ON account.privilege
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: confirm
CREATE TABLE account.confirm (
    account_id      INTEGER NOT NULL REFERENCES account.account PRIMARY KEY,
    code            VARCHAR(32) NOT NULL,
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER confirm_updated BEFORE UPDATE ON account.confirm
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- always have an admin role
INSERT INTO account.role(name, description)
    VALUES('admin', 'Super level admin user.');

-- ----------------------------------------------------------------------------
