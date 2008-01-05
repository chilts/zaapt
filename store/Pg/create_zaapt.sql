-- ----------------------------------------------------------------------------

-- infrastructure
CREATE TABLE base (
    inserted        TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated         TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE FUNCTION updated() RETURNS trigger as '
   BEGIN
      NEW.updated := CURRENT_TIMESTAMP;
      RETURN NEW;
   END;
' LANGUAGE plpgsql;

-- now for the main Zaapt config
CREATE SCHEMA zaapt;

-- table: model
CREATE SEQUENCE zaapt.model_id_seq;
CREATE TABLE zaapt.model (
    id              INTEGER NOT NULL DEFAULT nextval('zaapt.model_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL, -- like 'blog', 'news' and 'faq'
    title           TEXT NOT NULL, -- like 'Blog', 'News' and 'FAQ'
    module          TEXT, -- undef or like 'KiwiWriters::Zaapt::Store::Pg::Challenge'

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER model_updated BEFORE UPDATE ON zaapt.model
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: setting
CREATE SEQUENCE zaapt.setting_id_seq;
CREATE TABLE zaapt.setting (
    id              INTEGER NOT NULL DEFAULT nextval('zaapt.setting_id_seq'::TEXT) PRIMARY KEY,
    model_id        INTEGER NOT NULL REFERENCES zaapt.model,
    name            TEXT NOT NULL,
    value           TEXT NOT NULL,

    UNIQUE(model_id, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER setting_updated BEFORE UPDATE ON zaapt.setting
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- we now we need to tell zaapt of itself :-)
INSERT INTO zaapt.model(name, title, module) VALUES('zaapt', 'Zaapt', 'Zaapt::Store::Pg::Zaapt');

-- no settings for this model

-- ----------------------------------------------------------------------------
