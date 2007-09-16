## -------------------------------------------------------------------*-perl-*-
package Zaapt;

use strict;
use warnings;
use Carp;

our $VERSION = '0.1';

sub new {
    my ($class, $args) = @_;

    my $self = {};
    bless $self, ref $class || $class;

    # remember certain args
    # - store: 'Pg', 'MySQL'
    # - dbh: a DBI object (like from DBD::Pg)
    # - map: a mapping of names to packages
    foreach ( qw(store map dbh) ) {
        $self->{$_} = $args->{$_}
            if defined $args->{$_};
    }

    # so far, we have no models
    $self->{models} = {};

    return $self;
}

sub get_model {
    my ($self, $model) = @_;

    # return it if we already have it
    return $self->{models}{$model} if exists $self->{models}{$model};

    # see if there is a mapping for this $model
    if ( exists $self->{map}{$model} ) {
        eval "use $self->{map}{$model}";
        if ( $@ ) {
            die "Couldn't load Model '$self->{map}{$model}' module";
        }
        $self->{models}{$model} = "$self->{map}{$model}"->new({ dbh => $self->{dbh} });
        $self->{models}{$model}->parent( $self );
    }

    # or create one if just a name
    elsif ( $model =~ m{ \A \w+ \z }xms ) {
        eval "use Zaapt::Store::$self->{store}::$model";
        if ( $@ ) {
            die "Couldn't load Model 'Zaapt::Store::$self->{store}::$model' module";
        }
        $self->{models}{$model} = "Zaapt::Store::$self->{store}::$model"->new({ dbh => $self->{dbh} });
        $self->{models}{$model}->parent( $self );
    }

    # or create one from the '$model'
    elsif ( $model =~ m{ \A \w+(::\w+)* \z }xms ) {
        eval "use $model";
        if ( $@ ) {
            die "Couldn't load Model '$model' module";
        }
        $self->{models}{$model} = $model->new({ dbh => $self->{dbh} });
        $self->{models}{$model}->parent( $self );
    }
    else {
        warn "Unknown model: '$model'";
    }
    return $self->{models}{$model};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt> - a small lightweight CMS written in Perl/Mason using PostgreSQL

=head1 ABOUT

This package has no functionality except to hold a bit of documentation for
L<Zaapt>.

=head1 HOMEPAGE

The project page is at: http://code.google.com/p/zaapt/

The main information page is at: http://kapiti.geek.nz/software/zaapt.html

=head1 SUPPORT

There are some groups which can help with this set of modules. The main one is
the Google Groups group zaapt-discuss. For a Subversion commit list see
zaapt-commit. For notification of issues see zaapt-issue.

Bugs may be posted at: http://code.google.com/p/zaapt/issues/list

=head1 AUTHOR

Contact: Andrew Chilton B<E<lt>andychilton@gmail.comE<gt>>

Website: http://kapiti.geek.nz/

=head1 COPYRIGHT

Copyright (c) 2006 Andrew Chilton.

All rights reserved. This program is free software; you can redistribute and/or
modify it under the same terms as Perl itself.

All Zaapt::* modules written by me (Andrew Chilton) have this same copyright and
distribution terms. This is the definitive and overrides any others which may
omit this or which say otherwise.

=head1 VERSION

Version 0.1

=head1 SEE ALSO

perl(1)

=cut
