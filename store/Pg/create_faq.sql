-- ----------------------------------------------------------------------------

CREATE SCHEMA faq;

-- table: faq
CREATE SEQUENCE faq.faq_id_seq;
CREATE TABLE faq.faq (
    id              INTEGER NOT NULL DEFAULT nextval('faq.faq_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    admin_id        INTEGER NOT NULL REFERENCES account.permission,
    view_id         INTEGER NOT NULL REFERENCES account.permission,
    edit_id         INTEGER NOT NULL REFERENCES account.permission,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER faq_updated BEFORE UPDATE ON faq.faq
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN faq.faq.admin_id IS
    'Admin allows the user to do anything with the FAQ, including delete it';
COMMENT ON COLUMN faq.faq.view_id IS
    'View allows the user to see the questions and answers';
COMMENT ON COLUMN faq.faq.edit_id IS
    'Edit allows the user to edit the questions and answers, including adding a new one';

-- table: question
CREATE SEQUENCE faq.question_id_seq;
CREATE TABLE faq.question (
    id              INTEGER NOT NULL DEFAULT nextval('faq.question_id_seq'::TEXT) PRIMARY KEY,
    faq_id          INTEGER NOT NULL REFERENCES faq.faq,
    type_id         INTEGER NOT NULL REFERENCES common.type,
    question        TEXT NOT NULL,
    answer          TEXT NOT NULL,
    display         INTEGER NOT NULL DEFAULT currval('faq.question_id_seq'::TEXT),

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER question_updated BEFORE UPDATE ON faq.question
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- ----------------------------------------------------------------------------
