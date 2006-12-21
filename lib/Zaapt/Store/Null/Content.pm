## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Null::Content;
use base qw( Zaapt::Store::Null Zaapt::Model::Content );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# methods

sub content_ins { return; }
    my ($self, $a) = @_;
    $self->dbh()->do( $content_ins, undef, $a->{s_name} );
}

sub content_sel_all {
    my ($self) = @_;
    return $self->rows( $content_sel_all );
}

sub content_del {
    my ($self, $a) = @_;
    $self->dbh()->do( $content_del, undef, $a->{s_name} );
}

sub page_ins {
    my ($self, $a) = @_;
    $self->dbh()->do( $page_ins, undef, $a->{s_name}, $a->{p_name}, $a->{p_content}, $a->{p_type} );
}

sub page_upd {
    my ($self, $a) = @_;
    $self->dbh()->do( $page_upd, undef, $a->{p_name}, $a->{p_content}, $a->{p_type}, $a->{p_id} );
}

sub page_del {
    my ($self, $a) = @_;
    $self->dbh()->do( $page_del, undef, $a->{p_id} );
}

sub page_sel_id {
    my ($self, $a) = @_;
    return $self->row( $page_sel_id, $a->{p_id} );
}

sub page_sel_name {
    my ($self, $a) = @_;
    return $self->row( $page_sel_name, $a->{s_name}, $a->{p_name} );
}

sub page_sel_content_all {
    my ($self, $a) = @_;
    return $self->rows( $page_sel_content_all, $a->{s_name} );
}

sub page_sel_all {
    my ($self) = @_;
    return $self->rows( $page_sel_all );
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
