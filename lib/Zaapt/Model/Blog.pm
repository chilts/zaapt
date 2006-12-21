## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Blog;

use strict;
use warnings;
use Carp;
use base qw( Zaapt::Model );

## ----------------------------------------------------------------------------
# methods

my $interface = [
    { cmd => 'blog_ins', args => [ qw() ], desc => 'inserts a new blog' },
    { cmd => 'blog_sel_all', args => [ qw() ], desc => 'selects all the blogs' },
    { cmd => 'blog_del', args => [ qw(b_name) ], desc => 'deletes a blog' },
    { cmd => 'entry_ins', args => [ qw(b_name e_name e_title e_intro e_article) ], opt => [qw(draft)], desc => 'inserts a new entry' },
    { cmd => 'entry_sel_all', args => [ qw(b_name) ], desc => 'select all entries from a blog' },
    { cmd => 'entry_sel_recent', args => [ qw(b_name limit) ], desc => 'select recent entries from a blog (reverse order)' },
    { cmd => 'entry_sel_name', args => [ qw(b_name e_name) ], desc => 'select a named entry from a blog' },
    { cmd => 'tag_ins', args => [ qw(t_name) ], desc => 'add a generic tag' },
    { cmd => 'tag_sel_entries', args => [ qw(b_name t_name) ], desc => 'get all entries with this tag' },
    { cmd => 'tag_sel_count', args => [ qw(b_name) ], desc => 'lists the tags and count for this blog' },
    { cmd => 'entry_tag_ins', args => [ qw(b_name e_name t_name) ], desc => 'add a tag to an entry' },
    { cmd => 'entry_tag_sel_all', args => [ qw(b_name e_name) ], desc => 'list all tags on an entry' },
    { cmd => 'trackback_ins', args => [ qw(b_name e_name r_url r_blogname r_title r_excerpt) ], desc => 'add a trackback' },
];

foreach ( map { $_->{cmd} } @$interface ) {
    eval "sub $_ { croak \"Method '$_' should be implemented by inheriting classes\"; }";
}

sub interface {
    return $interface;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
