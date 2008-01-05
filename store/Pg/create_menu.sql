-- ----------------------------------------------------------------------------

CREATE SCHEMA menu;

-- table: menu
CREATE SEQUENCE menu.menu_id_seq;
CREATE TABLE menu.menu (
    id              INTEGER NOT NULL DEFAULT nextval('menu.menu_id_seq'::TEXT) PRIMARY KEY,
    name            TEXT NOT NULL,
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,
    admin_id        INTEGER NOT NULL REFERENCES account.permission,
    view_id         INTEGER NOT NULL REFERENCES account.permission,
    edit_id         INTEGER NOT NULL REFERENCES account.permission,

    UNIQUE(name),
    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER menu_updated BEFORE UPDATE ON menu.menu
    FOR EACH ROW EXECUTE PROCEDURE updated();

COMMENT ON COLUMN menu.menu.admin_id IS
    'Admin allows the user to do anything with the menu, including delete it';
COMMENT ON COLUMN menu.menu.view_id IS
    'View allows the user to see the items';
COMMENT ON COLUMN menu.menu.edit_id IS
    'Edit allows the user to add as well as edit the items';

-- table: item
CREATE SEQUENCE menu.item_id_seq;
CREATE TABLE menu.item (
    id              INTEGER NOT NULL DEFAULT nextval('menu.item_id_seq'::TEXT) PRIMARY KEY,
    menu_id         INTEGER NOT NULL REFERENCES menu.menu,
    display         INTEGER NOT NULL DEFAULT currval('menu.item_id_seq'::TEXT),
    level           INTEGER NOT NULL,
    url             TEXT NOT NULL,
    text            TEXT NOT NULL,
    ishtml          BOOLEAN NOT NULL DEFAULT False,

    LIKE base       INCLUDING DEFAULTS
);
CREATE TRIGGER item_updated BEFORE UPDATE ON menu.item
    FOR EACH ROW EXECUTE PROCEDURE updated();

CREATE INDEX item_display ON menu.item(display);

-- we now we need to tell Zaapt of the blog and it's settings
INSERT INTO zaapt.model(name, title, module) VALUES('menu', 'Menu', 'Zaapt::Store::Pg::Menu');

-- ----------------------------------------------------------------------------
