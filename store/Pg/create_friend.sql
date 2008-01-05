-- ----------------------------------------------------------------------------

CREATE SCHEMA friend;

-- table: friend
-- Note: since we'll only ever want (I never thought I'd say those words) _one_
-- set of friends, then we don't need any top-level container table.
CREATE SEQUENCE friend.friend_id_seq;
CREATE TABLE friend.friend (
    id              INTEGER NOT NULL DEFAULT nextval('friend.friend_id_seq'::TEXT) PRIMARY KEY,
    account_id      INTEGER NOT NULL REFERENCES account.account,
    to_id           INTEGER NOT NULL REFERENCES account.account,

    UNIQUE(account_id, to_id),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER friend_updated BEFORE UPDATE ON friend.friend
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN friend.friend.account_id IS
    'The account/person who added this friend.';
COMMENT ON COLUMN friend.friend.to_id IS
    'This signifies the acount.account who is the friend.';

-- we now we need to tell Zaapt of the blog and it's settings
INSERT INTO zaapt.model(name, title, module) VALUES('friend', 'Friend', 'Zaapt::Store::Pg::Friend');

-- ----------------------------------------------------------------------------
