-- ----------------------------------------------------------------------------

CREATE SCHEMA news;

-- table: news
CREATE SEQUENCE news.news_id_seq;
CREATE TABLE news.news (
    id              INTEGER NOT NULL DEFAULT nextval('news.news_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    show            INTEGER NOT NULL,
    admin_id        INTEGER NOT NULL REFERENCES account.role,
    view_id         INTEGER NOT NULL REFERENCES account.role,
    edit_id         INTEGER NOT NULL REFERENCES account.role,
    publish_id      INTEGER NOT NULL REFERENCES account.role,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER news_updated BEFORE UPDATE ON news.news
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN news.news.admin_id IS
    'Admin allows the user to do anything with the news, including delete it';
COMMENT ON COLUMN news.news.view_id IS
    'View allows the user to see the news and it\'s articles';
COMMENT ON COLUMN news.news.edit_id IS
    'Edit allows the user manipulate the articles (add/edit/del/tags)';
COMMENT ON COLUMN news.news.publish_id IS
    'Publish allows the user to publish or revoke any articles';

-- table: article
CREATE SEQUENCE news.article_id_seq;
CREATE TABLE news.article (
    id              INTEGER NOT NULL DEFAULT nextval('news.article_id_seq'::TEXT) PRIMARY KEY,
    news_id         INTEGER NOT NULL REFERENCES news.news,
    type_id         INTEGER NOT NULL REFERENCES common.type,
    title           TEXT NOT NULL,
    intro           TEXT NOT NULL,
    article         TEXT NOT NULL,
    draft           BOOLEAN DEFAULT False,
    comment         BOOLEAN NOT NULL DEFAULT False,
    trackback       BOOLEAN NOT NULL DEFAULT False,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER article_updated BEFORE UPDATE ON news.article
    FOR EACH ROW EXECUTE PROCEDURE updated();
CREATE INDEX article_inserted ON news.article(inserted);

-- ----------------------------------------------------------------------------
