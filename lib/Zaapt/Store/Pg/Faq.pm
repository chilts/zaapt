## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Faq;
use base qw( Zaapt::Store::Pg Zaapt::Model::Faq );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

# table names
my $faq_tablename = "faq.faq f";
my $question_tablename = "faq.question q";
my $type_tablename = "common.type t";

# helper
my $faq_cols = __PACKAGE__->_mk_cols( 'f', qw(id name title description r:admin_id r:view_id r:edit_id) );
my $question_cols = __PACKAGE__->_mk_cols( 'q', qw(id faq_id type_id question answer display) );
my $type_cols = __PACKAGE__->_mk_cols( 't', qw(id name) );

# joins
my $f_q_join = "JOIN $question_tablename ON (f.id = q.faq_id)";
my $q_t_join = "JOIN $type_tablename ON (q.type_id = t.id)";

# faq
my $ins_faq = __PACKAGE__->_mk_ins( 'faq.faq', 'name', 'title', 'description', 'admin_id', 'view_id', 'edit_id' );
my $upd_faq = __PACKAGE__->_mk_upd( 'faq.faq', 'id', qw(name title) ); # TODO: the privilege cols
my $del_faq = __PACKAGE__->_mk_del('faq.faq', 'id');
my $sel_faq = "SELECT $faq_cols FROM $faq_tablename WHERE f.id = ?";
my $sel_faq_all = "SELECT $faq_cols FROM $faq_tablename ORDER BY f.name";
my $sel_faq_using_name = "SELECT $faq_cols FROM $faq_tablename WHERE f.name = ?";

# question
my $ins_question = __PACKAGE__->_mk_ins( 'faq.question', 'faq_id', 'type_id', 'question', 'answer' );
my $upd_question = __PACKAGE__->_mk_upd( 'faq.question', 'id', qw(faq_id type_id question answer display) );
my $del_question = __PACKAGE__->_mk_del( 'faq.question', 'id');
my $sel_question = "SELECT $faq_cols, $question_cols, $type_cols FROM $faq_tablename $f_q_join $q_t_join WHERE q.id = ?";
my $sel_all_questions_in = "SELECT $faq_cols, $question_cols, $type_cols FROM $faq_tablename $f_q_join $q_t_join WHERE f.id = ? ORDER BY q.display";

# type
my $sel_all_types = "SELECT $type_cols FROM $type_tablename ORDER BY name";

## ----------------------------------------------------------------------------
# methods

# table: Faq

sub ins_faq {
    my ($self, $hr) = @_;
    $self->_do( $ins_faq, $hr->{f_name}, $hr->{f_title}, $hr->{f_description}, $hr->{_admin}, $hr->{_view}, $hr->{_edit} );
}

sub upd_faq {
    my ($self, $hr) = @_;
    $self->_do( $upd_faq, $hr->{f_name}, $hr->{f_title}, $hr->{f_id} );
}

sub del_faq {
    my ($self, $hr) = @_;
    $self->_do( $del_faq, $hr->{f_id} );
}

sub sel_faq_all {
    my ($self) = @_;
    return $self->_rows( $sel_faq_all );
}

sub sel_faq {
    my ($self, $hr) = @_;
    return $self->_row( $sel_faq, $hr->{f_id} );
}

sub sel_faq_using_name {
    my ($self, $hr) = @_;
    return $self->_row( $sel_faq_using_name, $hr->{f_name} );
}

# table: Content

sub ins_question {
    my ($self, $hr) = @_;
    $self->_do( $ins_question, $hr->{f_id}, $hr->{t_id}, $hr->{q_question}, $hr->{q_answer} );
}

sub upd_question {
    my ($self, $hr) = @_;
    $self->_do( $upd_question, $hr->{f_id}, $hr->{t_id}, $hr->{q_question}, $hr->{q_answer}, $hr->{q_display}, $hr->{q_id} );
}

sub del_question {
    my ($self, $hr) = @_;
    $self->_do( $del_question, $hr->{q_id} );
}

sub sel_question {
    my ($self, $hr) = @_;
    return $self->_row( $sel_question, $hr->{q_id} );
}

sub sel_all_questions_in {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_all_questions_in, $hr->{f_id} );
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM faq.question");
    $self->_do("DELETE FROM faq.faq");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
