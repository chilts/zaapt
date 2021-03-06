## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Dir;
use base qw( Zaapt::Store::Pg Zaapt::Model::Dir );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $schema = 'dir';

my $table = {
    dir => {
        schema => $schema,
        name   => 'dir',
        prefix => 'd',
        cols   => [ qw(id name title description path webdir ro:total r:admin_id r:view_id r:edit_id ts:inserted ts:updated) ],
    },
    file => {
        schema => $schema,
        name   => 'file',
        prefix => 'f',
        cols   => [
            'id',
            [ 'dir_id', 'fk', 'd_id' ],
            qw(name ext title description filename ts:inserted ts:updated)
        ],
    },
};

my $join = {
    d_f  => "JOIN $schema.file f ON (d.id = f.dir_id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_store_accessors( $schema, $table );

## ----------------------------------------------------------------------------

my $main_cols = "$table->{dir}{sql_sel_cols}, $table->{file}{sql_sel_cols}";
my $main_tables = "$table->{dir}{sql_fqt} $join->{d_f}";

# dir
__PACKAGE__->mk_selecter_from( $schema, $table->{dir} );
__PACKAGE__->mk_selecter_using_from( $schema, $table->{dir}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_dir_all', "SELECT $table->{dir}{sql_sel_cols} FROM $table->{dir}{sql_fqt} ORDER BY d.id", [] );

# file
__PACKAGE__->mk_select_row( 'sel_file', "SELECT $main_cols FROM $main_tables WHERE f.id = ?", [ 'f_id' ] );
__PACKAGE__->mk_selecter_using_from( $schema, $table->{file}, 'name' );
__PACKAGE__->mk_select_row( 'sel_file_in_dir', "SELECT $main_cols FROM $main_tables WHERE d.id = ? AND f.name = ?", [ 'd_id', 'f_name' ] );
__PACKAGE__->mk_select_rows( 'sel_file_all_in', "SELECT $main_cols FROM $main_tables WHERE d.id = ? ORDER BY f.name DESC", [ 'd_id' ] );

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM dir.file");
    $self->_do("DELETE FROM dir.dir");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
