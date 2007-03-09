## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Menu;
use base qw( Zaapt::Store::Pg Zaapt::Model::Menu );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $menu_tablename = "menu.menu m";
my $item_tablename = "menu.item i";

# helper
my $menu_cols = __PACKAGE__->_mk_cols( 'm', qw(id name title description r:admin_id r:view_id r:edit_id) );
my $item_cols = __PACKAGE__->_mk_cols( 'i', qw(id menu_id display level url text ishtml) );

my $item_seq = 'menu.item_id_seq';

# joins
my $m_i_join = "JOIN $item_tablename ON (m.id = i.menu_id)";

# menu
my $ins_menu = __PACKAGE__->_mk_ins( 'menu.menu', 'name', 'title', 'description', 'admin_id', 'view_id', 'edit_id' );
my $upd_menu = __PACKAGE__->_mk_upd( 'menu.menu', 'id', qw(name title description admin_id view_id edit_id) );
my $del_menu = __PACKAGE__->_mk_del('menu.menu', 'id');
my $sel_menu = "SELECT $menu_cols FROM $menu_tablename WHERE m.id = ?";
my $sel_menu_all = "SELECT $menu_cols FROM $menu_tablename ORDER BY m.name";
my $sel_menu_using_name = "SELECT $menu_cols FROM $menu_tablename WHERE m.name = ?";

# item
my $ins_item = __PACKAGE__->_mk_ins( 'menu.item', 'menu_id', 'level ', 'url', 'text', 'ishtml' );
my $upd_item = __PACKAGE__->_mk_upd( 'menu.item', 'id', qw(menu_id display level url text ishtml) );
my $del_item = __PACKAGE__->_mk_del( 'menu.item', 'id');
my $sel_item = "SELECT $menu_cols, $item_cols FROM $menu_tablename $m_i_join WHERE i.id = ?";
my $sel_all_items_in = "SELECT $menu_cols, $item_cols FROM $menu_tablename $m_i_join WHERE m.id = ? ORDER BY i.display";

# other
my $sel_items_for_move_up = "SELECT $item_cols FROM $item_tablename WHERE i.menu_id = ? AND i.display <= ? ORDER BY i.display DESC LIMIT 2";
my $sel_items_for_move_dn = "SELECT $item_cols FROM $item_tablename WHERE i.menu_id = ? AND i.display >= ? ORDER BY i.display LIMIT 2";

## ----------------------------------------------------------------------------
# methods

# table: Menu

sub ins_menu {
    my ($self, $hr) = @_;
    $self->_do( $ins_menu, $hr->{m_name}, $hr->{m_title}, $hr->{m_description}, $hr->{_admin}, $hr->{_view}, $hr->{_edit} );
}

sub upd_menu {
    my ($self, $hr) = @_;
    $self->_do( $upd_menu, $hr->{m_name}, $hr->{m_title}, $hr->{m_description}, $hr->{_admin}, $hr->{_view}, $hr->{_edit}, $hr->{m_id} );
}

sub del_menu {
    my ($self, $hr) = @_;
    $self->_do( $del_menu, $hr->{m_id} );
}

sub sel_menu_all {
    my ($self) = @_;
    return $self->_rows( $sel_menu_all );
}

sub sel_menu {
    my ($self, $hr) = @_;
    return $self->_row( $sel_menu, $hr->{m_id} );
}

sub sel_menu_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_menu_using_name, $hr->{m_name} );
}

# table: Item

sub ins_item {
    my ($self, $hr) = @_;
    $self->_do( $ins_item, $hr->{m_id}, $hr->{i_level}, $hr->{i_url}, $hr->{i_text}, $hr->{i_ishtml} );
}

sub upd_item {
    my ($self, $hr) = @_;
    $self->_do( $upd_item, $hr->{m_id}, $hr->{i_display}, $hr->{i_level}, $hr->{i_url}, $hr->{i_text}, $hr->{i_ishtml}, $hr->{i_id} );
}

sub del_item {
    my ($self, $hr) = @_;
    $self->_do( $del_item, $hr->{i_id} );
}

sub sel_item {
    my ($self, $hr) = @_;
    return $self->_row( $sel_item, $hr->{i_id} );
}

sub upd_item_move {
    my ($self, $hr, $sql) = @_;

    # start a transaction
    $self->dbh()->begin_work();

    # get the item in question, return if it doesn't exist
    my $item = $self->sel_item( $hr );
    return unless defined $item;

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

    $self->upd_item_move( $hr, $sel_items_for_move_up );
}

sub upd_item_move_dn {
    my ($self, $hr) = @_;

    $self->upd_item_move( $hr, $sel_items_for_move_dn );
}

sub sel_all_items_in {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_all_items_in, $hr->{m_id} );
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
