#!/usr/bin/perl
## ----------------------------------------------------------------------------

use strict;
use warnings;
use YAML::Syck;

## ----------------------------------------------------------------------------

# Note: these structure don't say which Storage they should use since that is
# up to the storage being used.

my $models = [
    {
        name => 'account',
        title => 'Account',
        depends => [ qw(zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(account ra role pa permission confirm) ],
    },
    {
        name => 'blog',
        title => 'Blog',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(blog entry entry_label comment trackback) ],
    },
    {
        name => 'common',
        title => 'Common',
        depends => [ qw(zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(label type) ],
    },
    {
        name => 'content',
        title => 'Content',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(content page) ],
    },
    {
        name => 'dir',
        title => 'Dir',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(dir file) ],
    },
    {
        name => 'faq',
        title => 'Faq',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(faq question) ],
    },
    {
        name => 'forum',
        title => 'Forum',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(forum topic post info) ],
    },
    {
        name => 'friend',
        title => 'Friend',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(friend) ],
    },
    {
        name => 'menu',
        title => 'Menu',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(menu item) ],
    },
    {
        name => 'message',
        title => 'Message',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(message) ],
    },
    {
        name => 'news',
        title => 'News',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(news article) ],
    },
    {
        name => 'session',
        title => 'Session',
        depends => [ qw(zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(session) ],
    },
    {
        name => 'zaapt',
        title => 'Zaapt',
        depends => [ qw() ],
        stores => [ 'psql' ],
        entities => [ qw(model) ],
    },
];

# we can always change this so that it creates other types of files
foreach my $model ( @$models ) {
    DumpFile("$model->{name}.yaml", $model);
}

## ----------------------------------------------------------------------------
