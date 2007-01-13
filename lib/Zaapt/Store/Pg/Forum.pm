## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Forum;
use base qw( Zaapt::Store::Pg Zaapt::Model::Forum );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $forum_tablename = "forum.forum f";
my $topic_tablename = "forum.topic tp";
my $post_tablename = "forum.post p";
my $type_tablename = "common.type t";
my $account_tablename = "account.account a";
my $poster_tablename = "account.account po";

# helper
my $forum_cols = __PACKAGE__->_mk_cols( 'f', qw(id name title description show topics posts poster_id r:admin_id r:view_id r:moderator_id) );
my $topic_cols = __PACKAGE__->_mk_cols( 'tp', qw(id forum_id account_id subject sticky locked posts poster_id ts:inserted ts:updated) );
my $post_cols = __PACKAGE__->_mk_cols( 'p', qw(id topic_id account_id message type_id ts:inserted ts:updated) );
my $type_cols = __PACKAGE__->_mk_cols( 't', qw(id name) );
my $account_cols = __PACKAGE__->_mk_cols( 'a', qw(id username ts:inserted ts:updated) );
my $poster_cols = __PACKAGE__->_mk_cols( 'po', qw(id username ts:inserted ts:updated) );

# joins
my $f_tp_join = "JOIN $topic_tablename ON (tp.forum_id = f.id)";
my $tp_p_join = "JOIN $post_tablename ON (p.topic_id = tp.id)";
my $p_t_join = "JOIN $type_tablename ON (p.type_id = t.id)";
my $tp_a_join = "JOIN $account_tablename ON (tp.account_id = a.id)";
my $tp_po_join = "LEFT JOIN $poster_tablename ON (tp.poster_id = po.id)";
my $p_a_join = "JOIN $account_tablename ON (p.account_id = a.id)";
my $f_po_join = "JOIN $poster_tablename ON (f.poster_id = po.id)";

# forum
my $ins_forum = __PACKAGE__->_mk_ins( 'forum.forum', qw(name title description show admin_id view_id moderator_id) );
my $upd_forum = __PACKAGE__->_mk_upd( 'forum.forum', 'id', qw(name title description show admin_id view_id moderator_id) );
my $sel_forum = "SELECT $forum_cols FROM $forum_tablename WHERE f.id = ?";
my $del_forum = __PACKAGE__->_mk_del('forum.forum', 'id');
my $sel_forum_using_name = "SELECT $forum_cols FROM $forum_tablename WHERE f.name = ?";
my $sel_forums_all = "SELECT $forum_cols, $poster_cols FROM $forum_tablename LEFT $f_po_join ORDER BY f.name";

# topic
my $ins_topic = __PACKAGE__->_mk_ins( 'forum.topic', qw(forum_id account_id subject) );
my $upd_topic = __PACKAGE__->_mk_upd( 'forum.topic', 'id', qw(forum_id account_id subject sticky locked));
my $del_topic = __PACKAGE__->_mk_del( 'forum.topic', 'id' );
my $sel_topic = "SELECT $forum_cols, $topic_cols FROM $forum_tablename $f_tp_join WHERE tp.id = ?";
my $sel_topic_if_forum = "SELECT $forum_cols, $topic_cols FROM $forum_tablename $f_tp_join $f_tp_join WHERE f.id = ? AND tp.id = ?";
my $sel_all_topics_in = "SELECT $forum_cols, $topic_cols, $account_cols FROM $forum_tablename $f_tp_join $tp_a_join $tp_po_join WHERE f.id = ? ORDER BY tp.sticky DESC, tp.updated DESC";
my $sel_all_topics_in_offset = "SELECT $forum_cols, $topic_cols, $account_cols FROM $forum_tablename $f_tp_join $tp_a_join $tp_po_join WHERE f.id = ? ORDER BY tp.sticky DESC, tp.updated DESC LIMIT ? OFFSET ?";
my $sel_latest_topics = "SELECT $forum_cols, $topic_cols FROM $forum_tablename $f_tp_join $f_tp_join WHERE f.id = ? ORDER BY tp.inserted DESC LIMIT ?";
my $sel_archive_topics = "SELECT $forum_cols, $topic_cols FROM $forum_tablename $f_tp_join $f_tp_join WHERE f.id = ? AND tp.inserted >= ?::DATE AND tp.inserted <= ?::DATE + ?::INTERVAL ORDER BY tp.inserted DESC";

# posts
my $ins_post = __PACKAGE__->_mk_ins( 'forum.post', qw(topic_id account_id message type_id) );
my $sel_all_posts_in = "SELECT $forum_cols, $topic_cols, $post_cols, $type_cols, $account_cols FROM $forum_tablename $f_tp_join $tp_p_join $p_t_join $p_a_join WHERE tp.id = ? ORDER BY p.inserted DESC";
my $sel_all_posts_in_offset = "SELECT $forum_cols, $topic_cols, $post_cols, $type_cols, $account_cols FROM $forum_tablename $f_tp_join $tp_p_join $p_t_join $p_a_join WHERE tp.id = ? ORDER BY p.inserted DESC LIMIT ? OFFSET ?";
my $del_posts_for_topic = __PACKAGE__->_mk_del( 'forum.post', 'topic_id' );

## ----------------------------------------------------------------------------
# methods

sub ins_forum {
    my ($self, $hr) = @_;
    $self->_do( $ins_forum, $hr->{f_name}, $hr->{f_title}, $hr->{f_description}, $hr->{f_show}, $hr->{_admin}, $hr->{_view}, $hr->{_moderator} );
}

sub upd_forum {
    my ($self, $hr) = @_;
    $self->_do( $upd_forum, $hr->{f_name}, $hr->{f_title}, $hr->{f_description}, $hr->{f_show}, $hr->{_admin}, $hr->{_view}, $hr->{_moderator}, $hr->{f_id} );
}

sub del_forum {
    my ($self, $hr) = @_;
    $self->_do( $del_forum, $hr->{f_id} );
}

sub sel_forum {
    my ($self, $hr) = @_;
    return $self->_row( $sel_forum, $hr->{f_id} );
}

sub sel_forums_all {
    my ($self) = @_;
    return $self->_rows( $sel_forums_all );
}

sub sel_forum_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_forum_using_name, $hr->{f_name} );
}

sub ins_topic {
    my ($self, $hr) = @_;
    $self->_do( $ins_topic, $hr->{f_id}, $hr->{a_id}, $hr->{tp_subject} );
}

sub ins_new_topic {
    my ($self, $hr) = @_;
    $self->dbh()->begin_work();
    $self->ins_topic( $hr );
    $hr->{tp_id} = $self->_currval( 'forum.topic_id_seq' );
    $self->ins_post( $hr );
    $self->dbh()->commit();
}

sub upd_topic {
    my ($self, $hr) = @_;
    $self->_do( $upd_topic, $hr->{f_id}, $hr->{a_id}, $hr->{tp_subject}, $hr->{tp_sticky}, $hr->{tp_locked}, $hr->{tp_id} );
}

sub del_topic {
    my ($self, $hr) = @_;
    $self->dbh()->begin_work();
    $self->_do( $del_posts_for_topic, $hr->{tp_id} );
    $self->_do( $del_topic, $hr->{tp_id} );
    $self->dbh()->commit();
}

sub sel_topic {
    my ($self, $hr) = @_;
    return $self->_row( $sel_topic, $hr->{tp_id} );
}

sub sel_topic_if_forum {
    my ($self, $hr) = @_;
    return $self->_row( $sel_topic_if_forum, $hr->{f_id}, $hr->{tp_id} );
}

sub sel_all_topics_in {
    my ($self, $hr) = @_;
    if ( defined $hr->{_limit} and defined $hr->{_offset} ) {
        return $self->_rows( $sel_all_topics_in_offset, $hr->{f_id}, $hr->{_limit}, $hr->{_offset} );
    }
    return $self->_rows( $sel_all_topics_in, $hr->{f_id} );
}

sub sel_latest_topics {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_latest_topics, $hr->{f_id}, $hr->{_limit} );
}

sub sel_all_posts_in {
    my ($self, $hr) = @_;
    if ( defined $hr->{_limit} and defined $hr->{_offset} ) {
        return $self->_rows( $sel_all_posts_in_offset, $hr->{tp_id}, $hr->{_limit}, $hr->{_offset} );
    }
    return $self->_rows( $sel_all_posts_in, $hr->{tp_id} );
}

sub ins_post {
    my ($self, $hr) = @_;
    $self->_do( $ins_post, $hr->{tp_id}, $hr->{a_id}, $hr->{p_message}, $hr->{t_id} );
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM forum.topic");
    $self->_do("DELETE FROM forum.forum");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
