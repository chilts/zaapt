## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Faq;
use base qw( Zaapt::Store::Pg Zaapt::Model::Faq );

use strict;
use warnings;

use Zaapt::Store::Pg::Common;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'faq';

my $tables = {
    faq => {
        schema => $schema,
        name   => 'faq',
        prefix => 'f',
        cols   => [ qw(id name title description r:admin_id r:view_id r:edit_id) ],
    },
    question => {
        schema => $schema,
        name   => 'question',
        prefix => 'q',
        cols   => [
            'id',
            [ 'faq_id', 'fk', 'f_id' ],
            [ 'type_id', 'fk', 't_id' ],
            qw(question answer display)
        ],
    },
    type => Zaapt::Store::Pg::Common->_get_table( 'type' ),
};

my $join = {
    f_q => "JOIN $schema.question q ON (f.id = q.faq_id)",
    q_t => "JOIN $tables->{type}{schema}.$tables->{type}{name} $tables->{type}{prefix} ON (q.type_id = $tables->{type}{prefix}.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_db_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# create some reusable sql
my $main_cols = "$tables->{faq}{sql_sel_cols}, $tables->{question}{sql_sel_cols}, $tables->{type}{sql_sel_cols}";
my $main_tables = "$tables->{faq}{sql_fqt} $join->{f_q} $join->{q_t}";

# faq
__PACKAGE__->_mk_selecter( $schema, $tables->{faq} );
__PACKAGE__->_mk_selecter_using( $schema, $tables->{faq}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_question_all', "SELECT $tables->{faq}{sql_sel_cols} FROM $tables->{faq}{sql_fqt} ORDER BY f.name" );

# question
__PACKAGE__->mk_select_row( 'sel_question', "SELECT $main_cols FROM $main_tables WHERE q.id = ?", [ 'q_id' ] );
__PACKAGE__->mk_select_rows( 'sel_question_all_in', "SELECT $main_cols FROM $main_tables WHERE c.id = ? ORDER BY p.name", [ 'c_id' ] );

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM faq.question");
    $self->_do("DELETE FROM faq.faq");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
