## -------------------------------------------------------------------*-perl-*-
package Zaapt::Utils::Valid;

use strict;
use warnings;

our $VERSION = '0.1';

my $err;

sub err {
    return $err;
}

sub is_valid_name {
    my ($name) = @_;

    $err = undef;

    # check that the FAQ name has been given
    unless ( defined $name ) {
        $err = 'Name is undefined';
        return;
    }

    if ( $name eq '' ) {
        $err = 'No name given';
        return;
    }

    unless ( $name =~ m{ \A [a-z0-9\-]+ \z }xms ) {
        $err = "Name must contain only 'a-z', '0-9' and '-'.";
        return;
    }
    return 1;
}

sub contains_something {
    my ($str, $name) = @_;

    unless ( defined $str ) {
        $err = "'$name' is undefined";
        return;
    }

    if ( $str eq '' ) {
        $err = "no '$name' given";
        return;
    }

    unless ( $str =~ m{ \S }xms ) {
        $err = "'$name' must contain something other than whitespace";
        return;
    }

    return 1;
}

# means 0 or more...
sub is_non_negative_integer {
    my ($num, $name) = @_;

    $err = undef;

    unless ( defined $num ) {
        $err = "'$name' is undefined";
        return;
    }

    if ( $num eq '' ) {
        $err = "no '$name' given";
        return;
    }

    unless ( $num =~ m{ \A \d+ \z }xms ) {
        $err = "'$name' ($num) must contain only digits";
        return;
    }

    # since $num contains ONLY 0-9 then it must be non-negative

    return 1;
}

# means greater than 0, ie. 1 or more...
sub is_positive_integer {
    my ($num, $name) = @_;

    $err = undef;

    unless ( defined $num ) {
        $err = "no '$name' given";
        return;
    }

    if ( $num eq '' ) {
        $err = "no '$name' given";
        return;
    }

    unless ( $num =~ m{ \A \d+ \z }xms ) {
        $err = "'$name' ($num) must contain only digits";
        return;
    }

    unless ( $num > 0 ) {
        $err = "'$name' ($num) must be greater than 0";
        return;
    }

    return 1;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Utils::Valid> - some validation routines which we need a lot of

=head1 AUTHOR

Contact: Andrew Chilton B<E<lt>andychilton@gmail.comE<gt>>

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
