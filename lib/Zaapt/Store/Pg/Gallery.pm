## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Gallery;
use base qw( Zaapt::Store::Pg Zaapt::Model::Gallery );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $schema = 'gallery';

my $table = {
    gallery => {
        name => 'gallery',
        prefix => 'g',
        cols => [ qw(id name title description path original webdir show extractexif ro:total r:admin_id r:view_id r:edit_id ts:inserted ts:updated) ],
    },
    picture => {
        name => 'picture',
        prefix => 'p',
        cols => [
            'id',
            [ 'gallery_id', 'fk', 'g_id' ],
            qw(name title description filename ts:inserted ts:updated)
        ],
    },
    field => {
        name => 'field',
        prefix => 'f',
        cols => [ qw(id name description ts:inserted ts:updated) ],
    },
    detail => {
        name => 'detail',
        prefix => 'd',
        cols => [
            'id',
            [ 'picture_id', 'fk', 'p_id' ],
            [ 'field_id', 'fk', 'f_id' ],
            qw(value ts:inserted ts:updated)
        ],
    },
    size => {
        name => 'size',
        prefix => 's',
        cols => [
            'id',
            [ 'gallery_id', 'fk', 'g_id' ],
            qw(size path ts:inserted ts:updated)
        ],
    },
};

my $join = {
    g_p  => "JOIN $schema.picture p ON (g.id = p.gallery_id)",
    g_s  => "JOIN $schema.size s ON (g.id = s.gallery_id)",
    p_d  => "JOIN $schema.detail d ON (p.id = d.picture_id)",
    d_f  => "JOIN $schema.field f ON (d.field_id = f.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_sql_accessors( $schema, $table );

## ----------------------------------------------------------------------------

# gallery
__PACKAGE__->mk_selecter( $schema, $table->{gallery}{name}, $table->{gallery}{prefix}, @{$table->{gallery}{cols}} );
__PACKAGE__->mk_selecter_using( $schema, $table->{gallery}{name}, $table->{gallery}{prefix}, 'name', @{$table->{gallery}{cols}} );
__PACKAGE__->mk_select_rows( 'sel_gallery_all', "SELECT $table->{gallery}{sql_sel_cols} FROM $table->{gallery}{sql_fqt} ORDER BY g.id", [] );

# picture
my $main_cols = "$table->{gallery}{sql_sel_cols}, $table->{picture}{sql_sel_cols}";
my $main_tables = "$table->{gallery}{sql_fqt} $join->{g_p}";

__PACKAGE__->mk_select_row( 'sel_picture', "SELECT $main_cols FROM $main_tables WHERE p.id = ?", [ 'p_id' ] );
__PACKAGE__->mk_select_row( 'sel_picture_in_gallery', "SELECT $main_cols FROM $main_tables WHERE g.id = ? AND p.name = ?", [ 'g_id', 'p_name' ] );
__PACKAGE__->mk_select_rows( 'sel_picture_all_in', "SELECT $main_cols FROM $main_tables WHERE g.id = ? ORDER BY p.name DESC", [ 'g_id' ] );
# warn "SELECT $main_cols FROM $main_tables WHERE g.id = ? ORDER BY p.name DESC";

# field
__PACKAGE__->mk_selecter( $schema, $table->{field}{name}, $table->{field}{prefix}, @{$table->{field}{cols}} );
__PACKAGE__->mk_selecter_using( $schema, $table->{field}{name}, $table->{field}{prefix}, 'name', @{$table->{field}{cols}} );
__PACKAGE__->mk_select_rows( 'sel_field_all', "SELECT $table->{field}{sql_sel_cols} FROM $table->{field}{sql_fqt} ORDER BY f.id" );

# assure that this field is there
sub ass_field {
    my ($self, $hr) = @_;

    # see if we already have it
    my $field = $self->sel_field_using_name( $hr );
    return $field if defined $field;

    # not yet in, insert then return it
    $self->ins_field( $hr );
    return $self->sel_field_using_name( $hr );
}

# detail
__PACKAGE__->mk_selecter( $schema, $table->{detail}{name}, $table->{detail}{prefix}, @{$table->{detail}{cols}} );

# size
__PACKAGE__->mk_select_row( 'sel_size', "SELECT $table->{gallery}{sql_sel_cols}, $table->{size}{sql_sel_cols} FROM $table->{gallery}{sql_fqt} $join->{g_s} WHERE s.id = ?", [ 's_id' ] );
__PACKAGE__->mk_select_rows( 'sel_size_all_in', "SELECT $table->{gallery}{sql_sel_cols}, $table->{size}{sql_sel_cols} FROM $table->{gallery}{sql_fqt} $join->{g_s} WHERE g.id = ? ORDER BY s.id", [ 'g_id' ] );

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM gallery.detail");
    $self->_do("DELETE FROM gallery.field");
    $self->_do("DELETE FROM gallery.picture");
    $self->_do("DELETE FROM gallery.size");
    $self->_do("DELETE FROM gallery.gallery");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
