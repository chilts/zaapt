## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Common;
use base qw( Zaapt::Store::Pg Zaapt::Model::Common );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $schema = 'common';

my $tables = {
    type => {
        schema => 'common',
        name   => 'type',
        prefix => 't',
        cols   => [ qw(id name ts:inserted ts:updated) ],
    },
    label => {
        schema => 'common',
        name   => 'label',
        prefix => 'l',
        cols   => [ qw(id name ts:inserted ts:updated) ],
    },
};

## ----------------------------------------------------------------------------

__PACKAGE__->_mk_sql( $schema, $tables );
__PACKAGE__->_mk_db_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# type
__PACKAGE__->_mk_selecter( $schema, $tables->{type} );
__PACKAGE__->mk_select_rows( 'sel_type_all', "SELECT $tables->{type}{sql_sel_cols} FROM $tables->{type}{sql_fqt} ORDER BY t.name", [] );
__PACKAGE__->_mk_selecter_using( $schema, $tables->{type}, 'name' );

# label
__PACKAGE__->_mk_selecter( $schema, $tables->{label} );
__PACKAGE__->_mk_selecter_using( $schema, $tables->{label}, 'name' );

## ----------------------------------------------------------------------------
# methods

sub _get_tables { return $tables; }

# assure that this label is in the store
sub ass_label {
    my ($self, $hr) = @_;

    # see if we already have it
    my $label = $self->sel_label_using_name( $hr );
    return $label if defined $label;

    # not yet in, insert then return it
    $self->ins_label( $hr );
    return $self->sel_label_using_name( $hr );
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM common.label");
    $self->_do("DELETE FROM common.type");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
