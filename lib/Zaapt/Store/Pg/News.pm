## ----------------------------------------------------------------------------
package Zaapt::Store::Pg::News;
use base qw( Zaapt::Store::Pg Zaapt::Model::News );

use strict;
use warnings;

use Zaapt::Store::Pg::Common;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'news';

my $tables = {
    news => {
        schema => $schema,
        name   => 'news',
        prefix => 'n',
        cols   => [ qw(id name title description show r:admin_id r:view_id r:edit_id r:publish_id) ],
    },
    article => {
        schema => $schema,
        name   => 'article',
        prefix => 'a',
        cols   => [
            'id',
            [ 'news_id', 'fk', 'n_id' ],
            [ 'type_id', 'fk', 't_id' ],
            qw(title intro article ts:inserted ts:updated)
        ],
    },
    type => Zaapt::Store::Pg::Common->_get_table( 'type' ),
};

my $join = {
    n_a => "JOIN $schema.article a ON (n.id = a.news_id)",
    a_t => "JOIN $tables->{type}{schema}.$tables->{type}{name} $tables->{type}{prefix} ON (a.type_id = $tables->{type}{prefix}.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple DB methods

# create some reusable sql
my $main_cols = "$tables->{news}{sql_sel_cols}, $tables->{article}{sql_sel_cols}, $tables->{type}{sql_sel_cols}";
my $main_tables = "$tables->{news}{sql_fqt} $join->{n_a} $join->{a_t}";

# news
__PACKAGE__->_mk_selecter( $schema, $tables->{news} );
__PACKAGE__->mk_selecter_using( $schema, $tables->{news}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_news_all', "SELECT $tables->{news}{sql_sel_cols} FROM $tables->{news}{sql_fqt} ORDER BY n.id" );

# article

__PACKAGE__->mk_select_row( 'sel_article', "SELECT $main_cols FROM $main_tables WHERE a.id = ?", [ 'a_id' ] );
__PACKAGE__->mk_select_rows( 'sel_article_all_in', "SELECT $main_cols FROM $main_tables WHERE n.id = ? ORDER BY a.id", [ 'n_id' ] );
__PACKAGE__->mk_select_row( 'sel_article_in_news', "SELECT $main_cols FROM $main_tables WHERE n.id = ? AND a.id = ?", [ 'n_id', 'a_id' ] );
__PACKAGE__->mk_select_rows( 'sel_article_latest', "SELECT $main_cols FROM $main_tables WHERE n.id = ? ORDER BY a.inserted DESC LIMIT ?", [ 'n_id', '_limit' ] );

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM news.article");
    $self->_do("DELETE FROM news.news");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
