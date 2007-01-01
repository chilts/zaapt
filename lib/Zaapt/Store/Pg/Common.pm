## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Common;
use base qw( Zaapt::Store::Pg Zaapt::Model::Common );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $type_tablename = "common.type t";

# helper
my $type_cols = __PACKAGE__->_mk_cols( 't', qw(id name) );

# type
my $sel_all_types = "SELECT $type_cols FROM $type_tablename ORDER BY name";
my $sel_type = __PACKAGE__->_mk_sel( 'common.type', 't', qw(id name) );

## ----------------------------------------------------------------------------
# methods

# table: type

# table: Content
sub sel_all_types {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_all_types );
}

sub sel_type {
    my ($self, $hr) = @_;
    return $self->_row( $sel_type, $hr->{t_id} );
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM common.type");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
