## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Session;
use base qw( Zaapt::Store::Pg Zaapt::Model::Session );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $schema = 'session';

my $table = {
    session => {
        schema => $schema,
        name   => 'session',
        prefix => 's',
        cols   => [ qw(id a_session ts:inserted ts:updated) ],
    },
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_store_accessors( $schema, $table );

## ----------------------------------------------------------------------------

# session
__PACKAGE__->mk_select_rows( 'sel_session_all', "SELECT $table->{session}{sql_sel_cols} FROM $table->{session}{sql_fqt} ORDER BY s.id", [] );

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM session.session");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
