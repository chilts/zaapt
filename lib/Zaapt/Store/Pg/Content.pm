## ----------------------------------------------------------------------------
package Zaapt::Store::Pg::Content;
use base qw( Zaapt::Store::Pg Zaapt::Model::Content );

use strict;
use warnings;

use Zaapt::Store::Pg::Common;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'content';

my $tables = {
    content => {
        schema => 'content',
        name => 'content',
        prefix => 'c',
        cols => [ qw(id name title description r:admin_id r:view_id r:edit_id r:publish_id ts:inserted ts:updated) ],
    },
    page => {
        schema => 'content',
        name => 'page',
        prefix => 'p',
        cols => [
            'id',
            [ 'content_id', 'fk', 'c_id' ],
            [ 'type_id', 'fk', 't_id' ],
            qw(name content ts:inserted ts:updated)
        ],
    },
    type => Zaapt::Store::Pg::Common->_get_table( 'type' ),
};

# need to add the join to common.type back in
my $join = {
    c_p => "JOIN $schema.page p ON (c.id = p.content_id)",
    p_t => "JOIN $tables->{type}{schema}.$tables->{type}{name} $tables->{type}{prefix} ON (p.type_id = $tables->{type}{prefix}.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_db_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# create some reusable sql
my $main_cols = "$tables->{content}{sql_sel_cols}, $tables->{page}{sql_sel_cols}, $tables->{type}{sql_sel_cols}";
my $main_tables = "$tables->{content}{sql_fqt} $join->{c_p} $join->{p_t}";

# content
__PACKAGE__->_mk_selecter( $schema, $tables->{content} );
__PACKAGE__->_mk_selecter_using( $schema, $tables->{content}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_content_all', "SELECT $tables->{content}{sql_sel_cols} FROM $tables->{content}{sql_fqt} ORDER BY c.id" );

# page
__PACKAGE__->mk_select_row( 'sel_page', "SELECT $main_cols FROM $main_tables WHERE p.id = ?", [ 'p_id' ] );
__PACKAGE__->mk_select_row( 'sel_page_using_name', "SELECT $main_cols FROM $main_tables WHERE p.name = ?", [ 'p_name' ] );
__PACKAGE__->mk_select_rows( 'sel_page_all_in', "SELECT $main_cols FROM $main_tables WHERE c.id = ? ORDER BY p.name", [ 'c_id' ] );

## ----------------------------------------------------------------------------

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM content.page");
    $self->_do("DELETE FROM content.content");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
