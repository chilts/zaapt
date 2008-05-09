-- this script presumes it is run on a fresh DB and that all the sequences are
-- set to 1

-- setup all the schema
\i /usr/share/zaapt/store/Pg/create_zaapt.sql
\i /usr/share/zaapt/store/Pg/create_common.sql
\i /usr/share/zaapt/store/Pg/create_account.sql
\i /usr/share/zaapt/store/Pg/create_content.sql

-- permissions
INSERT INTO
    account.permission(name, description)
VALUES
    ('admin', 'The Admin Permission')
;

-- home content
INSERT INTO
    content.content(name, title, description, admin_id, view_id, edit_id, publish_id)
VALUES
    ('home', 'Home', 'My Home Content', 1, 1, 1, 1)
;

-- home pages
INSERT INTO
    content.page(content_id, type_id, name, content)
VALUES
    (1, 1, 'index', '<p>Homepage</p>')
;

INSERT INTO
    content.page(content_id, type_id, name, content)
VALUES
    (1, 1, 'about', '<p>My name is Andy</p>')
;

-- account
INSERT INTO
    account.account(username, firstname, lastname, email, salt, password)
VALUES
    ('andy', 'Andrew', 'Chilton', 'andychilton@gmail.com', '', '')
;

-- blog schema
\i /usr/share/zaapt/store/Pg/create_blog.sql

-- a blog
INSERT INTO
    blog.blog(name, title, description, show, admin_id, view_id, edit_id, publish_id, comment_id, trackback_id)
VALUES
    ('blog', 'My Blog', 'Where I hang out.', 7, 1, 1, 1, 1, 1, 1)
;

-- blog entries
INSERT INTO
    blog.entry(blog_id, account_id, type_id, name, title, intro, article)
VALUES
    (1, 1, 1, 'first-entry', 'First Blog Entry', 'Welcome to my blog.', '<p>This is where I hang out</p>')
;

INSERT INTO
    blog.entry(blog_id, account_id, type_id, name, title, intro, article)
VALUES
    (1, 1, 1, 'the-second', 'Another Entry', 'Been here before.', '<p>Still here.</p>')
;

-- some labels
INSERT INTO common.label(name) VALUES('first');
INSERT INTO common.label(name) VALUES('second');
INSERT INTO common.label(name) VALUES('entry');

-- attach the labels to a blog entry
INSERT INTO blog.entry_label(entry_id, label_id) VALUES(1, 1);
INSERT INTO blog.entry_label(entry_id, label_id) VALUES(2, 2);
INSERT INTO blog.entry_label(entry_id, label_id) VALUES(1, 3);
INSERT INTO blog.entry_label(entry_id, label_id) VALUES(2, 3);
