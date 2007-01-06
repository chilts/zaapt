## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::News;
use base qw( Zaapt::Store::Pg Zaapt::Model::News );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $news_tablename = "news.news n";
my $article_tablename = "news.article a";
my $type_tablename = "common.type t";

# helper
my $news_cols = __PACKAGE__->_mk_cols( 'n', qw(id name title description show r:admin_id r:view_id r:edit_id r:publish_id) );
my $article_cols = __PACKAGE__->_mk_cols( 'a', qw(id news_id type_id title intro article ts:inserted ts:updated) );
my $type_cols = __PACKAGE__->_mk_cols( 't', qw(id name) );

# joins
my $n_a_join = "JOIN $article_tablename ON (a.news_id = n.id)";
my $e_t_join = "JOIN $type_tablename ON (a.type_id = t.id)";

# news
my $ins_news = __PACKAGE__->_mk_ins( 'news.news', qw(name title description show admin_id view_id edit_id publish_id) );
my $sel_news = "SELECT $news_cols FROM $news_tablename WHERE n.id = ?";
my $sel_news_using_name = "SELECT $news_cols FROM $news_tablename WHERE n.name = ?";
my $sel_news_all = "SELECT $news_cols FROM $news_tablename ORDER BY n.name";
my $del_news = __PACKAGE__->_mk_del('news.news', 'id');

# article
my $ins_article = __PACKAGE__->_mk_ins( 'news.article', qw(news_id type_id title intro article) );
my $upd_article = __PACKAGE__->_mk_upd( 'news.article', 'id', qw(news_id type_id title intro article));
my $del_article = __PACKAGE__->_mk_del( 'news.article', 'id' );
my $sel_article = "SELECT $news_cols, $article_cols, $type_cols FROM $news_tablename $n_a_join $e_t_join WHERE a.id = ?";
my $sel_article_in_news = "SELECT $news_cols, $article_cols, $type_cols FROM $news_tablename $n_a_join $e_t_join WHERE n.id = ? AND a.id = ?";
my $sel_all_articles_in = "SELECT $news_cols, $article_cols, $type_cols FROM $news_tablename $n_a_join $e_t_join WHERE n.id = ? ORDER BY a.inserted DESC";
my $sel_latest_articles = "SELECT $news_cols, $article_cols, $type_cols FROM $news_tablename $n_a_join $e_t_join WHERE n.id = ? ORDER BY a.inserted DESC LIMIT ?";
my $sel_archiva_articles = "SELECT $news_cols, $article_cols, $type_cols FROM $news_tablename $n_a_join $e_t_join WHERE n.id = ? AND a.inserted >= ?::DATE AND a.inserted <= ?::DATE + ?::INTERVAL ORDER BY a.inserted DESC";

## ----------------------------------------------------------------------------
# methods

sub ins_news {
    my ($self, $hr) = @_;
    $self->_do( $ins_news, $hr->{n_name}, $hr->{n_title}, $hr->{n_description}, $hr->{n_show}, $hr->{_admin}, $hr->{_view}, $hr->{_edit}, $hr->{_publish} );
}

sub del_news {
    my ($self, $hr) = @_;
    $self->_do( $del_news, $hr->{n_id} );
}

sub sel_news {
    my ($self, $hr) = @_;
    return $self->_row( $sel_news, $hr->{n_id} );
}

sub sel_news_all {
    my ($self) = @_;
    return $self->_rows( $sel_news_all );
}

sub sel_news_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_news_using_name, $hr->{n_name} );
}

sub ins_article {
    my ($self, $hr) = @_;
    $self->_do( $ins_article, $hr->{n_id}, $hr->{t_id}, $hr->{a_title}, $hr->{a_intro}, $hr->{a_article} );
}

sub upd_article {
    my ($self, $hr) = @_;
    $self->_do( $upd_article, $hr->{n_id}, $hr->{t_id}, $hr->{a_title}, $hr->{a_intro}, $hr->{a_article}, $hr->{a_id},  );
}

sub del_article {
    my ($self, $hr) = @_;
    $self->_do( $del_article, $hr->{a_id} );
}

sub sel_article {
    my ($self, $hr) = @_;
    return $self->_row( $sel_article, $hr->{a_id} );
}

sub sel_article_in_news {
    my ($self, $hr) = @_;
    return $self->_row( $sel_article_in_news, $hr->{n_id}, $hr->{a_id} );
}

sub sel_all_articles_in {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_all_articles_in, $hr->{n_id} );
}

sub sel_latest_articles {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_latest_articles, $hr->{n_id}, $hr->{_limit} );
}

sub sel_archive_articles {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_archiva_articles, $hr->{n_id}, $hr->{_from}, $hr->{_from}, $hr->{_for} );
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM news.article");
    $self->_do("DELETE FROM news.news");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
