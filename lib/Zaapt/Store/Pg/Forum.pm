## ----------------------------------------------------------------------------
package Zaapt::Store::Pg::Forum;
use base qw( Zaapt::Store::Pg Zaapt::Model::Forum );

use strict;
use warnings;
use Data::Dumper;

use Zaapt::Store::Pg::Common;
use Zaapt::Store::Pg::Account;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'forum';

my $tables = {
    forum => {
        schema => $schema,
        name   => 'forum',
        prefix => 'f',
        cols   => [ qw(id name title description show ro:topics ro:posts poster_id r:admin_id r:view_id r:moderator_id ts:inserted ts:updated) ],
    },
    topic => {
        schema => $schema,
        name   => 'topic',
        prefix => 'tp',
        cols   => [
            'id',
            [ 'forum_id', 'fk', 'f_id' ],
            [ 'account_id', 'fk', 'a_id' ],
            qw(subject sticky locked posts poster_id ts:inserted ts:updated)
        ],
    },
    post => {
        schema => $schema,
        name   => 'post',
        prefix => 'p',
        cols   => [
            'id',
            [ 'topic_id', 'fk', 'tp_id' ],
            [ 'account_id', 'fk', 'a_id' ],
            'message',
            [ 'type_id', 'fk', 't_id' ],
            qw(ts:inserted ts:updated)
        ],
    },
    type => Zaapt::Store::Pg::Common->_get_table( 'type' ),
    account => Zaapt::Store::Pg::Account->_get_table( 'account' ),
    poster => Zaapt::Store::Pg::Account->_get_table( 'account' ),
    info => {
        schema => $schema,
        name   => 'info',
        prefix => 'i',
        cols   => [
            [ 'account_id', 'fk', 'a_id' ],
            qw(posts signature ts:inserted ts:updated)
        ],
    },
};

# change the poster table to have prefix 'p'
$tables->{poster}{prefix} = 'po';

# joins
my $join = {
    f_tp  => "JOIN $schema.topic tp ON (tp.forum_id = f.id)",
    tp_p  => "JOIN $schema.post p ON (p.topic_id = tp.id)",
    p_t   => "JOIN common.type t ON (p.type_id = t.id)",
    tp_a  => "JOIN account.account a ON (tp.account_id = a.id)",
    tp_po => "LEFT JOIN account.account po ON (tp.poster_id = po.id)",
    p_a   => "JOIN account.account a ON (p.account_id = a.id)",
    f_po  => "LEFT JOIN account.account po ON (f.poster_id = po.id)",
    p_i   => "LEFT JOIN $schema.info i ON (p.account_id = i.account_id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# create some reusable sql
my $forum_cols = "$tables->{forum}{sql_sel_cols}, $tables->{poster}{sql_sel_cols}";
my $forum_tables = "$tables->{forum}{sql_fqt} $join->{f_po}";
my $topic_cols = "$tables->{forum}{sql_sel_cols}, $tables->{topic}{sql_sel_cols}, $tables->{account}{sql_sel_cols}";
my $topic_tables = "$tables->{forum}{sql_fqt} $join->{f_tp} $join->{tp_a}";
my $post_cols = "$tables->{forum}{sql_sel_cols}, $tables->{topic}{sql_sel_cols}, $tables->{post}{sql_sel_cols}";
my $post_tables = "$tables->{forum}{sql_fqt} $join->{f_tp} $join->{tp_p}";

# forum
__PACKAGE__->_mk_selecter( $schema, $tables->{forum} );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{forum}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_forum_all', "SELECT $forum_cols FROM $forum_tables ORDER BY f.name" );
__PACKAGE__->_mk_select_count( $tables->{forum} );

# topic
__PACKAGE__->mk_select_row( 'sel_topic', "SELECT $topic_cols FROM $topic_tables WHERE tp.id = ?", [ 'tp_id' ] );
__PACKAGE__->_mk_select_count( $tables->{topic} );
__PACKAGE__->_mk_select_rows_offset( 'sel_topic_all_in', "SELECT $topic_cols, $tables->{poster}{sql_sel_cols} FROM $topic_tables $join->{tp_po} WHERE f.id = ? ORDER BY tp.sticky DESC, tp.updated DESC", [ 'f_id' ] );

# posts
__PACKAGE__->mk_select_row( 'sel_post', "SELECT $post_cols FROM $post_tables WHERE p.id = ?", [ 'p_id' ] );
__PACKAGE__->mk_select_rows( 'sel_post_all', "SELECT $tables->{forum}{sql_sel_cols} FROM $tables->{forum}{sql_fqt} ORDER BY f.name" );
__PACKAGE__->_mk_select_rows_offset( 'sel_post_all_in', "SELECT $post_cols, CASE WHEN current_timestamp < p.inserted + '1 hour'::INTERVAL THEN 1 ELSE 0 END AS p_editable, $tables->{type}{sql_sel_cols}, $tables->{account}{sql_sel_cols}, $tables->{info}{sql_sel_cols} FROM $post_tables $join->{p_t} $join->{p_a} $join->{p_i} WHERE tp.id = ? ORDER BY p.inserted", [ 'tp_id' ] );
__PACKAGE__->_mk_select_rows_offset( 'sel_post_all_for', "SELECT $post_cols, $tables->{account}{sql_sel_cols} FROM $post_tables $join->{tp_a} WHERE p.account_id = ? ORDER BY p.inserted DESC", [ 'p_id' ] );
__PACKAGE__->_mk_select_count( $tables->{post} );

# info
__PACKAGE__->_mk_selecter( $schema, $tables->{info} );

## ----------------------------------------------------------------------------
# methods

my $ins_topic = __PACKAGE__->_mk_ins( 'forum.topic', qw(forum_id account_id subject) );
sub ins_topic {
    my ($self, $hr) = @_;
    warn "sql=$ins_topic";
    warn Dumper($hr);
    return $self->_do( $ins_topic, map { $hr->{$_} } qw(f_id a_id tp_subject) );
}

sub ins_new_topic {
    my ($self, $hr) = @_;
    $self->dbh()->begin_work();
    $self->ins_topic( $hr );
    $hr->{tp_id} = $self->_currval( 'forum.topic_id_seq' );
    $self->ins_post( $hr );
    $self->dbh()->commit();
}

# ToDo: one left
my $del_posts_for_topic = __PACKAGE__->_mk_del( 'forum.post', 'topic_id' );
my $del_topic = __PACKAGE__->_mk_del( 'forum.topic', 'id' );

sub del_topic {
    my ($self, $hr) = @_;
    $self->dbh()->begin_work();
    $self->_do( $del_posts_for_topic, $hr->{tp_id} );
    $self->_do( $del_topic, $hr->{tp_id} );
    $self->dbh()->commit();
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM forum.post");
    $self->_do("DELETE FROM forum.topic");
    $self->_do("DELETE FROM forum.forum");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
