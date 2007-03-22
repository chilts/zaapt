## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Common;
use base qw( Zaapt::Store::Pg Zaapt::Model::Common );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $type_tablename = "common.type t";
my $label_tablename = "common.label l";

# helper
my $type_cols = __PACKAGE__->_mk_cols( 't', qw(id name) );
my $label_cols = __PACKAGE__->_mk_cols( 'l', qw(id name) );

# table: type
my $sel_all_types = "SELECT $type_cols FROM $type_tablename ORDER BY name";
my $sel_type = __PACKAGE__->_mk_sel( 'common.type', 't', qw(id name) );
my $sel_type_using_name = "SELECT $type_cols FROM $type_tablename WHERE t.name = ?";

# table: label
my $ins_label = __PACKAGE__->_mk_ins( 'common.label', 'name' );
my $upd_label = __PACKAGE__->_mk_upd( 'common.label', 'id', qw(name) );
my $del_label = __PACKAGE__->_mk_del( 'common.label', 'id');
my $sel_label = "SELECT $label_cols FROM $label_tablename WHERE l.id = ?";
my $sel_label_using_name = "SELECT $label_cols FROM $label_tablename WHERE l.name = ?";

## ----------------------------------------------------------------------------
# methods

# table: type
sub sel_all_types {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_all_types );
}

sub sel_type {
    my ($self, $hr) = @_;
    return $self->_row( $sel_type, $hr->{t_id} );
}

sub sel_type_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_type_using_name, $hr->{t_name} );
}

# table: label
sub ins_label {
    my ($self, $hr) = @_;
    $self->_do( $ins_label, $hr->{l_name} );
}

sub upd_label {
    my ($self, $hr) = @_;
    $self->_do( $upd_label, $hr->{l_name}, $hr->{l_id} );
}

sub del_label {
    my ($self, $hr) = @_;
    $self->_do( $del_label, $hr->{l_id} );
}

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

sub sel_label {
    my ($self, $hr) = @_;
    return $self->_row( $sel_label, $hr->{l_id} );
}

sub sel_label_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_label_using_name, $hr->{l_name} );
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
