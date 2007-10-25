## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Calendar;
use base qw( Zaapt::Store::Pg Zaapt::Model::Calendar );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'calendar';

my $tables = {
    calendar => {
        schema => $schema,
        name => 'calendar',
        prefix => 'c',
        cols => [ qw(id name title description ro:total r:admin_id r:view_id r:edit_id ts:inserted ts:updated) ],
    },
    event => {
        schema => $schema,
        name => 'event',
        prefix => 'e',
        cols => [
            'id',
            [ 'calendar_id', 'fk', 'c_id' ],
            qw(name title description ts:startts ts:endts allday location link lat lng zoom ts:inserted ts:updated) ],
    },
};

my $join = {
    c_e => "JOIN $schema.event e ON (c.id = e.calendar_id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_db_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# create some reusable sql
my $main_cols = "$tables->{calendar}{sql_sel_cols}, $tables->{event}{sql_sel_cols}";
my $main_tables = "$tables->{calendar}{sql_fqt} $join->{c_e}";

# calendar
__PACKAGE__->_mk_selecter( $schema, $tables->{calendar} );
__PACKAGE__->_mk_selecter_using( $schema, $tables->{calendar}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_calendar_all', "SELECT $tables->{calendar}{sql_sel_cols} FROM $tables->{calendar}{sql_fqt} ORDER BY c.id", [] );

# event
__PACKAGE__->mk_select_row( 'sel_event', "SELECT $main_cols FROM $main_tables WHERE e.id = ?", [ 'e_id' ] );
__PACKAGE__->mk_select_row( 'sel_event_using_name', "SELECT $main_cols FROM $main_tables WHERE c.id = ? AND e.name = ?", [ 'c_id', 'e_name' ] );
__PACKAGE__->mk_select_row( 'sel_event_in', "SELECT $main_cols FROM $main_tables WHERE c.id = ? AND e.name = ?", [ 'c_id', 'e_name' ] );
__PACKAGE__->mk_select_rows( 'sel_event_all_in', "SELECT $main_cols FROM $main_tables WHERE c.id = ? ORDER BY e.startts", [ 'c_id' ] );

## ----------------------------------------------------------------------------
# other calendar accessors

# none

## ----------------------------------------------------------------------------

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->dbh()->do( "DELETE FROM calendar.event" );
    $self->dbh()->do( "DELETE FROM calendar.calendar" );
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------