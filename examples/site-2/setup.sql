-- this script presumes it is run on a fresh DB and that all the sequences are
-- set to 1

-- setup the previous schema
\i /usr/share/zaapt/examples/site-1/setup.sql

-- add the menu model
\i /usr/share/zaapt/store/Pg/create_menu.sql

-- now add a menu
INSERT INTO
    menu.menu(name, title, description, admin_id, view_id, edit_id)
VALUES
    ('rhs-menu', 'RHS Menu', 'The menu on the RHS.', 1, 1, 1)
;

-- and some items to show
INSERT INTO
    menu.item(menu_id, display, level, url, text)
VALUES
    (1, 1, 1, '/', 'Home')
;

INSERT INTO
    menu.item(menu_id, display, level, url, text)
VALUES
    (1, 2, 2, '/about.html', 'About')
;

INSERT INTO
    menu.item(menu_id, display, level, url, text)
VALUES
    (1, 3, 1, '/blog/', 'My Blog')
;

INSERT INTO
    menu.item(menu_id, display, level, url, text)
VALUES
    (1, 4, 1, 'http://kapiti.geek.nz/', 'Other Site')
;
