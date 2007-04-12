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
        name => 'blog',
        prefix => 'b',
        cols => [ qw(id name title description show comment trackback r:admin_id r:view_id r:edit_id r:publish_id ts:inserted ts:updated) ],
    },
    entry => {
        name => 'entry',
        prefix => 'e',
        cols => [
            'id',
            [ 'blog_id', 'fk', 'b_id' ],
            [ 'account_id', 'fk', 'a_id' ],
            [ 'type_id', 'fk', 't_id' ],
            qw(name title intro article draft comment trackback ts:inserted ts:updated)
        ],
    },
    entry_label => {
        name => 'entry_label',
        prefix => 'el',
        cols => [
            'id',
            [ 'entry_id', 'fk', 'e_id' ],
            [ 'label_id', 'fk', 'l_id' ],
            qw(ts:inserted ts:updated)
        ],
    },
    comment => {
        name => 'comment',
        prefix => 'c',
        cols => [
            'id',
            [ 'entry_id', 'fk', 'e_id' ],
            qw(name email homepage comment status ts:inserted ts:updated)
        ],
    },
    trackback => {
        name => 'trackback',
        prefix => 'tr',
        cols => [
            'id',
            [ 'entry_id', 'fk', 'e_id' ],
            qw(url blogname title excerpt status ts:inserted ts:updated)
        ],
    },
};

my $join = {
    b_e  => "JOIN $schema.entry e ON (b.id = e.blog_id)",
    e_t  => "JOIN common.type t ON (e.type_id = t.id)",
    e_l  => "JOIN $schema.entry_label el ON (el.entry_id = e.id) JOIN common.label l ON (el.label_id = l.id)",
    e_c  => "JOIN $schema.comment c ON (c.entry_id = e.id)",
    e_tr => "JOIN $schema.trackback tr ON (tr.entry_id = e.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_sql_accessors( $schema, $table );

# add the 'foreign' tables
$table->{account} = Zaapt::Store::Pg::Account->get_table_details('account');
__PACKAGE__->_mk_sql_for( $table->{account}{schema}, $table->{account} );

$table->{type} = Zaapt::Store::Pg::Common->get_table_details('type');
__PACKAGE__->_mk_sql_for( $table->{type}{schema}, $table->{type} );

## ----------------------------------------------------------------------------

# blog
__PACKAGE__->mk_selecter( $schema, $table->{blog}{name}, $table->{blog}{prefix}, @{$table->{blog}{cols}} );
__PACKAGE__->mk_selecter_using( $schema, $table->{blog}{name}, $table->{blog}{prefix}, 'name', @{$table->{blog}{cols}} );
__PACKAGE__->mk_select_rows( 'sel_blog_all', "SELECT $table->{blog}{sql_sel_cols} FROM $table->{blog}{sql_fqt} ORDER BY b.id", [] );

# entry
my $blog_cols = "$table->{blog}{sql_sel_cols}, $table->{entry}{sql_sel_cols}, $table->{type}{sql_sel_cols}";
my $blog_joins = "$table->{blog}{sql_fqt} $join->{b_e} $join->{e_t}";

__PACKAGE__->mk_select_row( 'sel_entry', "SELECT $blog_cols FROM $blog_joins WHERE e.id = ?", [ 'e_id' ] );

__PACKAGE__->mk_select_row( 'sel_entry_in_blog', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? AND e.name = ?", [ 'b_id', 'e_name' ] );

__PACKAGE__->mk_select_rows( 'sel_entry_all_in', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? ORDER BY e.inserted DESC", [ 'b_id' ] );

__PACKAGE__->mk_select_rows( 'sel_entry_latest_in', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? ORDER BY e.inserted DESC LIMIT ?", [ 'b_id', '_limit' ] );

__PACKAGE__->mk_select_rows( 'sel_entry_archive_in', "SELECT $blog_cols FROM $blog_joins WHERE b.id = ? AND e.inserted >= ?::DATE AND e.inserted <= ?::DATE ORDER BY e.inserted DESC", [ 'b_id', '_from', '_to' ] );

# entry_label
my $ins_entry_label = __PACKAGE__->_mk_ins( 'blog.entry_label', qw(entry_id label_id) );

## ----------------------------------------------------------------------------
# methods

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
