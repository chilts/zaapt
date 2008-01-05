#!/usr/bin/perl
## ----------------------------------------------------------------------------

use strict;
use warnings;
use YAML::Syck;

## ----------------------------------------------------------------------------

my $models = [
    {
        name => 'account',
        depends => [ qw(zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(account ra role pa permission confirm) ],
    },
    {
        name => 'blog',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(blog entry entry_label comment trackback) ],
    },
    {
        name => 'common',
        depends => [ qw(zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(label type) ],
    },
    {
        name => 'content',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(content page) ],
    },
    {
        name => 'dir',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(dir file) ],
    },
    {
        name => 'faq',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(faq question) ],
    },
    {
        name => 'forum',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(forum topic post info) ],
    },
    {
        name => 'friend',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(friend) ],
    },
    {
        name => 'menu',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(menu item) ],
    },
    {
        name => 'message',
        depends => [ qw(account zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(message) ],
    },
    {
        name => 'news',
        depends => [ qw(account common zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(news article) ],
    },
    {
        name => 'session',
        depends => [ qw(zaapt) ],
        stores => [ 'psql' ],
        entities => [ qw(session) ],
    },
    {
        name => 'zaapt',
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
