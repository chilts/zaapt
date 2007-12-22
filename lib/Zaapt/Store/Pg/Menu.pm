## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Menu;
use base qw( Zaapt::Store::Pg Zaapt::Model::Menu );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'menu';

my $tables = {
    menu => {
        schema => $schema,
        name   => 'menu',
        prefix => 'm',
        cols   => [ qw(id name title description r:admin_id r:view_id r:edit_id) ],
    },
    item => {
        schema => $schema,
        name   => 'item',
        prefix => 'i',
        cols   => [
            'id',
            [ 'menu_id', 'fk', 'm_id' ],
            qw(display level url text ishtml)
        ],
    },
};

my $join = {
    m_i => "JOIN $schema.item i ON (m.id = i.menu_id)",
};

my $item_seq = 'menu.item_id_seq';

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# create some reusable sql
my $main_cols = "$tables->{menu}{sql_sel_cols}, $tables->{item}{sql_sel_cols}";
my $main_tables = "$tables->{menu}{sql_fqt} $join->{m_i}";

# menu
__PACKAGE__->_mk_selecter( $schema, $tables->{menu} );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{menu}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_menu_all', "SELECT $tables->{menu}{sql_sel_cols} FROM $tables->{menu}{sql_fqt} ORDER BY m.name", [] );

# item
__PACKAGE__->mk_select_row( 'sel_item', "SELECT $main_cols FROM $main_tables WHERE i.id = ?", [ 'i_id' ] );
__PACKAGE__->mk_select_rows( 'sel_item_all_in', "SELECT $main_cols FROM $main_tables WHERE m.id = ? ORDER BY i.display", [ 'm_id' ] );

## ----------------------------------------------------------------------------
# complex accessors

# need this since i_display should be left to it's default value
# ToDo: put an extra thing in Pg.pm to help do this (e.g. def:display)
my $ins_item = __PACKAGE__->_mk_ins( 'menu.item', 'menu_id', 'level', 'url', 'text', 'ishtml' );
sub ins_item {
    my ($self, $hr) = @_;
    $self->_do( $ins_item, $hr->{m_id}, $hr->{i_level}, $hr->{i_url}, $hr->{i_text}, $hr->{i_ishtml} );
}

# move up/dn
my $i_t = $tables->{item};
my $sel_items_for_move_up = "SELECT $i_t->{sql_sel_cols} FROM $i_t->{sql_fqt} WHERE i.menu_id = ? AND i.display <= ? ORDER BY i.display DESC LIMIT 2";
my $sel_items_for_move_dn = "SELECT $i_t->{sql_sel_cols} FROM $i_t->{sql_fqt} WHERE i.menu_id = ? AND i.display >= ? ORDER BY i.display LIMIT 2";

sub upd_item_move {
    my ($self, $sql, $hr) = @_;

    # start a transaction
    $self->dbh()->begin_work();

    # get the item in question, return if it doesn't exist
    my $item = $self->sel_item( $hr );
    unless ( defined $item ) {
        $self->dbh()->rollback();
        return;
    }

    # get the two rows to be exchanged
    my $rows = $self->_rows( $sql, $hr->{m_id}, $item->{i_display} );
    unless ( @$rows == 2 ) {
        $self->dbh()->rollback();
        return;
    }

    # set the display to be a new value, then do swapsies
    my $seq_id = $self->_nextval( $item_seq );
    $self->upd_item({ i_id => $rows->[0]{i_id}, i_display => $seq_id });
    $self->upd_item({ i_id => $rows->[1]{i_id}, i_display => $rows->[0]{i_display} });
    $self->upd_item({ i_id => $rows->[0]{i_id}, i_display => $rows->[1]{i_display} });

    $self->dbh()->commit();
}

sub upd_item_move_up {
    my ($self, $hr) = @_;

    $self->upd_item_move( $sel_items_for_move_up, $hr );
}

sub upd_item_move_dn {
    my ($self, $hr) = @_;

    $self->upd_item_move( $sel_items_for_move_dn, $hr );
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM menu.item");
    $self->_do("DELETE FROM menu.menu");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
