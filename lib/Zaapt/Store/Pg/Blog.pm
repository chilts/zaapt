## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Blog;
use base qw( Zaapt::Store::Pg Zaapt::Model::Blog );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $blog_tablename = "blog.blog b";
my $entry_tablename = "blog.entry e";
my $type_tablename = "common.type t";
my $entry_label_tablename = 'blog.entry_label el';

# helper
my $blog_cols = __PACKAGE__->_mk_cols( 'b', qw(id name title description show comment trackback r:admin_id r:view_id r:edit_id r:publish_id) );
my $entry_cols = __PACKAGE__->_mk_cols( 'e', qw(id blog_id type_id name title intro article draft comment trackback ts:inserted ts:updated) );
my $type_cols = __PACKAGE__->_mk_cols( 't', qw(id name) );
my $el_tablename = __PACKAGE__->_mk_cols( 'el', qw(entry_id label_id) );

# joins
my $b_e_join = "JOIN $entry_tablename ON (b.id = e.blog_id)";
my $e_t_join = "JOIN $type_tablename ON (t.id = e.type_id)";

# blog
my $ins_blog = __PACKAGE__->_mk_ins( 'blog.blog', qw(name title description show comment trackback admin_id view_id edit_id publish_id) );
my $sel_blog = "SELECT $blog_cols FROM $blog_tablename WHERE b.id = ?";
my $sel_blog_using_name = "SELECT $blog_cols FROM $blog_tablename WHERE b.name = ?";
my $sel_blog_all = "SELECT $blog_cols FROM $blog_tablename ORDER BY b.name";
my $del_blog = __PACKAGE__->_mk_del('blog.blog', 'id');

# entry
my $ins_entry = __PACKAGE__->_mk_ins( 'blog.entry', qw(blog_id type_id name title intro article draft comment trackback) );
my $upd_entry = __PACKAGE__->_mk_upd( 'blog.entry', 'id', qw(blog_id type_id name title intro article draft comment trackback));
my $del_entry = __PACKAGE__->_mk_del( 'blog.entry', 'id' );
my $sel_entry = "SELECT $blog_cols, $entry_cols, $type_cols FROM $blog_tablename $b_e_join $e_t_join WHERE e.id = ?";
my $sel_entry_in_blog = "SELECT $blog_cols, $entry_cols, $type_cols FROM $blog_tablename $b_e_join $e_t_join WHERE b.id = ? AND e.name = ?";
my $sel_all_entries_in = "SELECT $blog_cols, $entry_cols, $type_cols FROM $blog_tablename $b_e_join $e_t_join WHERE b.id = ? ORDER BY e.inserted DESC";
my $sel_latest_entries = "SELECT $blog_cols, $entry_cols, $type_cols FROM $blog_tablename $b_e_join $e_t_join WHERE b.id = ? ORDER BY e.inserted DESC LIMIT ?";
my $sel_archive_entries = "SELECT $blog_cols, $entry_cols, $type_cols FROM $blog_tablename $b_e_join $e_t_join WHERE b.id = ? AND e.inserted >= ?::DATE AND e.inserted <= ?::DATE + ?::INTERVAL ORDER BY e.inserted DESC";

# entry_label
my $ins_entry_label = __PACKAGE__->_mk_ins( 'blog.entry_label', qw(entry_id label_id) );

## ----------------------------------------------------------------------------
# methods

sub ins_blog {
    my ($self, $hr) = @_;
    $self->_do( $ins_blog, $hr->{b_name}, $hr->{b_title}, $hr->{b_description}, $hr->{b_show}, $hr->{b_comment}, $hr->{b_trackback}, $hr->{_admin}, $hr->{_view}, $hr->{_edit}, $hr->{_publish} );
}

sub del_blog {
    my ($self, $hr) = @_;
    $self->_do( $del_blog, $hr->{b_id} );
}

sub sel_blog {
    my ($self, $hr) = @_;
    return $self->_row( $sel_blog, $hr->{b_id} );
}

sub sel_blog_all {
    my ($self) = @_;
    return $self->_rows( $sel_blog_all );
}

sub sel_blog_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_blog_using_name, $hr->{b_name} );
}

sub ins_entry {
    my ($self, $hr) = @_;
    $self->_do( $ins_entry, $hr->{b_id}, $hr->{t_id}, $hr->{e_name}, $hr->{e_title}, $hr->{e_intro}, $hr->{e_article}, $hr->{e_draft}, $hr->{e_comment}, $hr->{e_trackback} );
}

sub upd_entry {
    my ($self, $hr) = @_;
    $self->_do( $upd_entry, $hr->{b_id}, $hr->{t_id}, $hr->{e_name}, $hr->{e_title}, $hr->{e_intro}, $hr->{e_article}, $hr->{e_draft}, $hr->{e_comment}, $hr->{e_trackback}, $hr->{e_id},  );
}

sub del_entry {
    my ($self, $hr) = @_;
    $self->_do( $del_entry, $hr->{e_id} );
}

sub sel_entry {
    my ($self, $hr) = @_;
    return $self->_row( $sel_entry, $hr->{e_id} );
}

sub sel_entry_in_blog {
    my ($self, $hr) = @_;
    return $self->_row( $sel_entry_in_blog, $hr->{b_id}, $hr->{e_name} );
}

sub sel_all_entries_in {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_all_entries_in, $hr->{b_id} );
}

sub sel_latest_entries {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_latest_entries, $hr->{b_id}, $hr->{_limit} );
}

sub sel_archive_entries {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_archive_entries, $hr->{b_id}, $hr->{_from}, $hr->{_from}, $hr->{_for} );
}

sub ins_label {
    my ($self, $hr) = @_;

    my $common_model = $self->parent()->get_model('Common');

    warn "c_m=" . ref $common_model;

    $self->dbh()->begin_work();
    my $label = $common_model->ass_label( $hr );
    $self->_do( $ins_entry_label, $hr->{e_id}, $label->{l_id} );
    $self->dbh()->commit();
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM blog.entry");
    $self->_do("DELETE FROM blog.blog");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
