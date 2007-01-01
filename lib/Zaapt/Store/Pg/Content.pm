## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Content;
use base qw( Zaapt::Store::Pg Zaapt::Model::Content );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $content_tablename = "content.content c";
my $page_tablename = "content.page p";
my $type_tablename = "content.type t";

# helper
my $content_cols = __PACKAGE__->_mk_cols( 'c', qw(id name title description r:admin_id r:view_id r:edit_id r:publish_id) );
my $page_cols = __PACKAGE__->_mk_cols( 'p', qw(id content_id type_id name content) );
my $type_cols = __PACKAGE__->_mk_cols( 't', qw(id name) );

# joins
my $c_p_join = "JOIN $page_tablename ON (c.id = p.content_id)";
my $p_t_join = "JOIN $type_tablename ON (t.id = p.type_id)";

# content
my $ins_content = __PACKAGE__->_mk_ins( 'content.content', qw(name title description admin_id view_id edit_id publish_id) );
my $sel_content = "SELECT $content_cols FROM $content_tablename WHERE c.id = ?";
my $sel_content_using_name = "SELECT $content_cols FROM $content_tablename WHERE c.name = ?";
my $sel_content_all = "SELECT $content_cols FROM $content_tablename ORDER BY c.name";
my $del_content = __PACKAGE__->_mk_del('content.content', 'id');

# page
my $ins_page = __PACKAGE__->_mk_ins( 'content.page', 'content_id', 'type_id', 'name', 'content' );
my $upd_page = __PACKAGE__->_mk_upd( 'content.page', 'id', qw(content_id type_id name content));
my $del_page = __PACKAGE__->_mk_del( 'content.page', 'id');
my $sel_page = "SELECT $content_cols, $page_cols, $type_cols FROM $content_tablename $c_p_join $p_t_join WHERE p.id = ?";
my $sel_page_using_name = "SELECT $content_cols, $page_cols, $type_cols FROM $content_tablename $c_p_join $p_t_join WHERE c.id = ? AND p.name = ?";
my $sel_all_pages_in = "SELECT $content_cols, $page_cols, $type_cols FROM $content_tablename $c_p_join $p_t_join WHERE c.id = ? ORDER BY p.name";
my $sel_all_pages = "SELECT $page_cols FROM $page_tablename ORDER BY content_name, name";

# type
my $sel_all_types = "SELECT $type_cols FROM $type_tablename ORDER BY name";

## ----------------------------------------------------------------------------
# methods

sub ins_content {
    my ($self, $hr) = @_;
    $self->_do( $ins_content, $hr->{c_name}, $hr->{c_title}, $hr->{c_description}, $hr->{_admin}, $hr->{_view}, $hr->{_edit}, $hr->{_publish} );
}

sub sel_content_all {
    my ($self) = @_;
    return $self->_rows( $sel_content_all );
}

sub sel_content {
    my ($self, $hr) = @_;
    return $self->_row( $sel_content, $hr->{c_id} );
}

sub sel_content_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_content_using_name, $hr->{c_name} );
}

sub del_content {
    my ($self, $hr) = @_;
    $self->_do( $del_content, $hr->{c_id} );
}

sub ins_page {
    my ($self, $hr) = @_;
    $self->_do( $ins_page, $hr->{c_id}, $hr->{t_id}, $hr->{p_name}, $hr->{p_content} );
}

sub sel_all_pages_in {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_all_pages_in, $hr->{c_id} );
}

sub sel_page_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_page_using_name, $hr->{c_id}, $hr->{p_name} );
}

sub upd_page {
    my ($self, $hr) = @_;
    $self->_do( $upd_page, $hr->{c_id}, $hr->{t_id}, $hr->{p_name}, $hr->{p_content}, $hr->{p_id} );
}

sub del_page {
    my ($self, $hr) = @_;
    $self->_do( $del_page, $hr->{p_id} );
}

sub sel_page {
    my ($self, $hr) = @_;
    return $self->_row( $sel_page, $hr->{p_id} );
}

sub sel_all_pages {
    my ($self) = @_;
    my $content = {};
    my $sth = $self->{dbh}->prepare( $sel_all_pages );
    $sth->execute();
    while ( my $row ) {
        push @{$content->{$row->{c_name}}}, $row;
    }
    return $content;
}

sub sel_all_types {
    my ($self) = @_;
    return $self->_rows( $sel_all_types );
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM content.page");
    $self->_do("DELETE FROM content.content");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
