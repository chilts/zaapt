-- ----------------------------------------------------------------------------

CREATE SCHEMA message;

CREATE SEQUENCE message.message_id_seq;
CREATE TABLE message.message (
    id              INTEGER NOT NULL DEFAULT nextval('message.message_id_seq'::TEXT) PRIMARY KEY,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    to_id           INTEGER NOT NULL REFERENCES account.account,
    subject         VARCHAR(255) NOT NULL,
    message         TEXT NOT NULL,
    read            BOOLEAN NOT NULL DEFAULT False,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER message_updated BEFORE UPDATE ON message.message
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- ----------------------------------------------------------------------------
