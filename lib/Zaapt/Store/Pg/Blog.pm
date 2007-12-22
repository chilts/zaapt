## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Blog;
use base qw( Zaapt::Store::Pg Zaapt::Model::Blog );

use strict;
use warnings;

use Zaapt::Store::Pg::Account;
use Zaapt::Store::Pg::Common;

## ----------------------------------------------------------------------------
# constants

my $schema = 'blog';

my $table = {
    blog => {
        schema => $schema,
        name   => 'blog',
        prefix => 'b',
        cols   => [ qw(id name title description show moderate comment trackback r:admin_id r:view_id r:edit_id r:publish_id r:comment_id r:trackback_id ts:inserted ts:updated) ],
    },
    entry => {
        schema => $schema,
        name   => 'entry',
        prefix => 'e',
        cols   => [
            'id',
            [ 'blog_id', 'fk', 'b_id' ],
            [ 'account_id', 'fk', 'a_id' ],
            [ 'type_id', 'fk', 't_id' ],
            qw(name title intro article draft comment trackback ro:comments ro:trackbacks ts:inserted ts:updated)
        ],
    },
    entry_label => {
        schema => $schema,
        name   => 'entry_label',
        prefix => 'el',
        cols   => [
            'id',
            [ 'entry_id', 'fk', 'e_id' ],
            [ 'label_id', 'fk', 'l_id' ],
            qw(ts:inserted ts:updated)
        ],
    },
    comment => {
        schema => $schema,
        name   => 'comment',
        prefix => 'c',
        cols   => [
            'id',
            [ 'entry_id', 'fk', 'e_id' ],
            qw(name email homepage comment status ts:inserted ts:updated)
        ],
    },
    trackback => {
        schema => $schema,
        name   => 'trackback',
        prefix => 'tr',
        cols   => [
            'id',
            [ 'entry_id', 'fk', 'e_id' ],
            qw(url blogname title excerpt status ts:inserted ts:updated)
        ],
    },
    account => Zaapt::Store::Pg::Account->_get_table( 'account' ),
    type  => Zaapt::Store::Pg::Common->_get_table( 'type' ),
    label => Zaapt::Store::Pg::Common->_get_table( 'label' ),
};

my $join = {
    b_e  => "JOIN $schema.entry e ON (b.id = e.blog_id)",
    e_t  => "JOIN common.type t ON (e.type_id = t.id)",
    e_l  => "JOIN $schema.entry_label el ON (el.entry_id = e.id) JOIN common.label l ON (el.label_id = l.id)",
    e_c  => "JOIN $schema.comment c ON (c.entry_id = e.id)",
    e_tr => "JOIN $schema.trackback tr ON (tr.entry_id = e.id)",
    e_a  => "JOIN account.account a ON (e.account_id = a.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_store_accessors( $schema, $table );

## ----------------------------------------------------------------------------

# blog
__PACKAGE__->mk_selecter( $schema, $table->{blog}{name}, $table->{blog}{prefix}, @{$table->{blog}{cols}} );
__PACKAGE__->mk_selecter_using_from( $schema, $table->{blog}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_blog_all', "SELECT $table->{blog}{sql_sel_cols} FROM $table->{blog}{sql_fqt} ORDER BY b.id", [] );

# entry
my $blog_cols = "$table->{blog}{sql_sel_cols}, $table->{entry}{sql_sel_cols}, $table->{type}{sql_sel_cols}, $table->{account}{sql_sel_cols}";
my $blog_joins = "$table->{blog}{sql_fqt} $join->{b_e} $join->{e_t} $join->{e_a}";

__PACKAGE__->mk_select_row( 'sel_entry', "SELECT $blog_cols FROM $blog_joins WHERE e.id = ?", [ 'e_id' ] );

__PACKAGE__->mk_select_row( 'sel_entry_in_blog', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? AND e.name = ?", [ 'b_id', 'e_name' ] );

__PACKAGE__->mk_select_rows( 'sel_entry_all_in', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? ORDER BY e.inserted DESC", [ 'b_id' ] );

__PACKAGE__->mk_select_rows( 'sel_entry_latest', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? ORDER BY e.inserted DESC LIMIT ?", [ 'b_id', '_limit' ] );

__PACKAGE__->mk_select_rows( 'sel_entry_archive', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? AND e.inserted >= ?::DATE AND e.inserted <= ?::DATE + ?::INTERVAL ORDER BY e.inserted DESC", [ 'b_id', '_from', '_from', '_for' ] );

__PACKAGE__->mk_select_rows( 'sel_entry_label', "SELECT $blog_cols FROM $blog_joins $join->{e_l} WHERE b.id = ? AND l.name = ? ORDER BY e.inserted DESC", [ 'b_id', 'l_name' ] );

__PACKAGE__->mk_select_rows( 'sel_label_all_for', "SELECT $table->{label}{sql_sel_cols} FROM $table->{entry}{sql_fqt} $join->{e_l} WHERE e.id = ? ORDER BY l.name", [ 'e_id' ] );

# comment
__PACKAGE__->mk_selecter( $schema, $table->{comment}{name}, $table->{comment}{prefix}, @{$table->{comment}{cols}} );
__PACKAGE__->mk_select_rows( 'sel_comments_for', "SELECT $table->{comment}{sql_sel_cols} FROM $table->{entry}{sql_fqt} $join->{e_c} WHERE e.id = ? AND c.status = ? ORDER BY c.inserted", [ 'e_id', 'c_status' ] );
__PACKAGE__->mk_select_rows( 'sel_comments_for_blog', "SELECT $table->{entry}{sql_sel_cols}, $table->{comment}{sql_sel_cols} FROM $table->{entry}{sql_fqt} $join->{e_c} WHERE e.blog_id = ? AND c.status = ? ORDER BY c.inserted", [ 'b_id', 'c_status' ] );
__PACKAGE__->mk_select_rows( 'sel_comment_latest', "SELECT $table->{blog}{sql_sel_cols}, $table->{entry}{sql_sel_cols}, $table->{comment}{sql_sel_cols} FROM $table->{blog}{sql_fqt} $join->{b_e} $join->{e_c} WHERE b.id = ? AND c.status = 'acc' ORDER BY c.inserted DESC LIMIT ?", [ 'b_id', '_limit' ] );

# trackbacks
__PACKAGE__->mk_select_rows( 'sel_trackbacks_for', "SELECT $table->{trackback}{sql_sel_cols} FROM $table->{entry}{sql_fqt} $join->{e_tr} WHERE e.id = ? AND tr.status = ? ORDER BY tr.inserted", [ 'e_id', 'tr_status' ] );

## ----------------------------------------------------------------------------
# methods

sub ins_label {
    my ($self, $hr) = @_;

    my $common_model = $self->parent()->get_model('Common');

    my $label = $common_model->ass_label( $hr );
    $self->ins_entry_label({ e_id => $hr->{e_id}, l_id => $label->{l_id} });
}

sub del_entry_label_for {
    my ($self, $hr) = @_;
    $self->_do("DELETE FROM blog.entry_label WHERE entry_id = ?", $hr->{e_id});
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
