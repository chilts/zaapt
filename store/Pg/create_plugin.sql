-- ----------------------------------------------------------------------------

CREATE SCHEMA plugin;

-- table: plugin
CREATE SEQUENCE plugin.plugin_id_seq;
CREATE TABLE plugin.plugin (
    id              INTEGER NOT NULL DEFAULT nextval('plugin.plugin_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL, -- like 'blog', 'news' and 'faq'
    title           TEXT NOT NULL, -- like 'Blog', 'News' and 'FAQ'
    module          TEXT, -- undef or like 'KiwiWriters::Zaapt::Store::Pg::Challenge'

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER plugin_updated BEFORE UPDATE ON plugin.plugin
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- table: setting
CREATE SEQUENCE plugin.setting_id_seq;
CREATE TABLE plugin.setting (
    id              INTEGER NOT NULL DEFAULT nextval('plugin.setting_id_seq'::TEXT) PRIMARY KEY,
    plugin_id       INTEGER NOT NULL REFERENCES plugin.plugin,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    value           TEXT NOT NULL,

    UNIQUE(plugin_id, name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER setting_updated BEFORE UPDATE ON plugin.setting
    FOR EACH ROW EXECUTE PROCEDURE updated();

-- we now we need to tell plugin of itself :-)
INSERT INTO plugin.plugin(name, title, module) VALUES('plugin', 'Plugin', 'Zaapt::Store::Pg::Plugin');

-- ----------------------------------------------------------------------------
