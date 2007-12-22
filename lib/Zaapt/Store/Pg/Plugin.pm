## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Plugin;
use base qw( Zaapt::Store::Pg Zaapt::Model::Plugin );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'plugin';

my $tables = {
    plugin => {
        schema => $schema,
        name => 'plugin',
        prefix => 'p',
        cols => [ qw(id name title module ts:inserted ts:updated) ],
    },
    setting => {
        schema => $schema,
        name => 'setting',
        prefix => 's',
        cols => [
            'id',
            [ 'plugin_id', 'fk', 'p_id' ],
            qw(name title description value ts:inserted ts:updated) ],
    },
};

my $join = {
    p_s => "JOIN $schema.setting s ON (p.id = s.plugin_id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# create some reusable sql
my $main_cols = "$tables->{plugin}{sql_sel_cols}, $tables->{setting}{sql_sel_cols}";
my $main_tables = "$tables->{plugin}{sql_fqt} $join->{p_s}";

# plugin
__PACKAGE__->_mk_selecter( $schema, $tables->{plugin} );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{plugin}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_plugin_all', "SELECT $tables->{plugin}{sql_sel_cols} FROM $tables->{plugin}{sql_fqt} ORDER BY p.id", [] );

# setting
__PACKAGE__->mk_select_row( 'sel_setting', "SELECT $main_cols FROM $main_tables WHERE s.id = ?", [ 's_id' ] );
__PACKAGE__->mk_select_row( 'sel_setting_using_name', "SELECT $main_cols FROM $main_tables WHERE p.id = ? AND s.name = ?", [ 'p_id', 's_name' ] );
__PACKAGE__->mk_select_rows( 'sel_setting_all_in', "SELECT $main_cols FROM $main_tables WHERE p.id = ? ORDER BY s.name", [ 'p_id' ] );

## ----------------------------------------------------------------------------
# other plugin accessors

# none

## ----------------------------------------------------------------------------

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->dbh()->do( "DELETE FROM plugin.setting" );
    $self->dbh()->do( "DELETE FROM plugin.plugin" );
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
