## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Zaapt;
use base qw( Zaapt::Store::Pg Zaapt::Model::Zaapt );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $schema = 'zaapt';

my $table = {
    model => {
        schema => $schema,
        name   => 'model',
        prefix => 'm',
        cols   => [ qw(id name title module ts:inserted ts:updated) ],
    },
    setting => {
        schema => $schema,
        name   => 'setting',
        prefix => 's',
        cols   => [
            'id',
            [ 'model_id', 'fk', 'm_id' ],
            qw(name value ts:inserted ts:updated)
        ],
    },
};

my $join = {
    m_s  => "JOIN $schema.setting s ON (m.id = s.model_id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_store_accessors( $schema, $table );

## ----------------------------------------------------------------------------

# model
__PACKAGE__->mk_selecter_from( $schema, $table->{model} );
__PACKAGE__->mk_select_rows( 'sel_model_all', "SELECT $table->{model}{sql_sel_cols} FROM $table->{model}{sql_fqt} ORDER BY m.name", [] );

# setting
my $setting_cols = "$table->{model}{sql_sel_cols}, $table->{setting}{sql_sel_cols}";
my $setting_joins = "$table->{model}{sql_fqt} $join->{m_s}";
__PACKAGE__->mk_select_row( 'sel_setting', "SELECT $setting_cols FROM $setting_joins WHERE s.id = ?", [ 's_id' ] );
__PACKAGE__->mk_select_row( 'sel_setting_in_model', "SELECT $setting_cols FROM $setting_joins WHERE m.id = ? AND s.name = ?", [ 'b_id', 'e_name' ] );
__PACKAGE__->mk_select_rows( 'sel_setting_all_in', "SELECT $setting_cols FROM $setting_joins WHERE m.id = ? ORDER BY s.name DESC", [ 'm_id' ] );

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM zaapt.setting");
    $self->_do("DELETE FROM zaapt.model");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
