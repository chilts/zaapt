## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Faq;
use base qw( Zaapt::Store::Pg Zaapt::Model::Faq );

use strict;
use warnings;

use Zaapt::Store::Pg::Common;

## ----------------------------------------------------------------------------
# constants

# schema name
my $schema = 'faq';

my $tables = {
    faq => {
        schema => $schema,
        name   => 'faq',
        prefix => 'f',
        cols   => [ qw(id name title description r:admin_id r:view_id r:edit_id) ],
    },
    question => {
        schema => $schema,
        name   => 'question',
        prefix => 'q',
        cols   => [
            'id',
            [ 'faq_id', 'fk', 'f_id' ],
            [ 'type_id', 'fk', 't_id' ],
            qw(question answer display)
        ],
    },
    type => Zaapt::Store::Pg::Common->_get_table( 'type' ),
};

my $join = {
    f_q => "JOIN $schema.question q ON (f.id = q.faq_id)",
    q_t => "JOIN $tables->{type}{schema}.$tables->{type}{name} $tables->{type}{prefix} ON (q.type_id = $tables->{type}{prefix}.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $tables );

## ----------------------------------------------------------------------------
# simple accessors

# create some reusable sql
my $main_cols = "$tables->{faq}{sql_sel_cols}, $tables->{question}{sql_sel_cols}, $tables->{type}{sql_sel_cols}";
my $main_tables = "$tables->{faq}{sql_fqt} $join->{f_q} $join->{q_t}";

# faq
__PACKAGE__->_mk_selecter( $schema, $tables->{faq} );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{faq}, 'name' );
__PACKAGE__->mk_select_rows( 'sel_faq_all', "SELECT $tables->{faq}{sql_sel_cols} FROM $tables->{faq}{sql_fqt} ORDER BY f.name" );

# question
__PACKAGE__->mk_select_row( 'sel_question', "SELECT $main_cols FROM $main_tables WHERE q.id = ?", [ 'q_id' ] );
__PACKAGE__->mk_select_rows( 'sel_question_all_in', "SELECT $main_cols FROM $main_tables WHERE f.id = ? ORDER BY q.display", [ 'f_id' ] );

## ----------------------------------------------------------------------------
# complex accessors

# need this since q_display should be left to it's default value
# ToDo: put an extra thing in Pg.pm to help do this (e.g. def:display)
my $ins_question = __PACKAGE__->_mk_ins( 'faq.question', 'faq_id', 'question', 'answer', 'type_id' );
sub ins_question {
    my ($self, $hr) = @_;
    $self->_do( $ins_question, $hr->{f_id}, $hr->{q_question}, $hr->{q_answer}, $hr->{t_id} );
}

# move up/dn
my $q_tbl = $tables->{question};
my $sel_questions_for_move = "SELECT $q_tbl->{sql_sel_cols} FROM $q_tbl->{sql_fqt} WHERE q.faq_id = ?";
my $sel_questions_for_move_up = $sel_questions_for_move . " AND q.display <= ? ORDER BY q.display DESC LIMIT 2";
my $sel_questions_for_move_dn = $sel_questions_for_move . " AND q.display >= ? ORDER BY q.display LIMIT 2";

sub upd_question_move {
    my ($self, $sql, $hr) = @_;

    # start a transaction
    $self->dbh()->begin_work();

    # get the question in question, return if it doesn't exist
    my $question = $self->sel_question( $hr );
    unless ( defined $question ) {
        $self->dbh()->rollback();
        # warn "didn't find the question: $hr->{q_id}";
        return;
    }

    # get the two rows to be exchanged
    my $rows = $self->_rows( $sql, $hr->{f_id}, $question->{q_display} );
    unless ( @$rows == 2 ) {
        $self->dbh()->rollback();
        # warn "didn't get two rows";
        return;
    }

    # set the display to be a new value (a negative of itself), then do swapsies
    $self->upd_question({ q_id => $rows->[0]{q_id}, q_display => -$rows->[0]{q_display} });
    $self->upd_question({ q_id => $rows->[1]{q_id}, q_display => $rows->[0]{q_display} });
    $self->upd_question({ q_id => $rows->[0]{q_id}, q_display => $rows->[1]{q_display} });

    $self->dbh()->commit();
}

sub upd_question_move_up {
    my ($self, $hr) = @_;

    $self->upd_question_move( $sel_questions_for_move_up, $hr );
}

sub upd_question_move_dn {
    my ($self, $hr) = @_;

    $self->upd_question_move( $sel_questions_for_move_dn, $hr );
}

## ----------------------------------------------------------------------------
# methods

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
