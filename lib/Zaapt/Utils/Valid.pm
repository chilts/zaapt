## -------------------------------------------------------------------*-perl-*-
package Zaapt::Utils::Valid;

use strict;
use warnings;
use Carp;

use DateTime;

our $VERSION = '0.1';

my $err;

sub err {
    return $err;
}

# usually for all 'name' fields, hence it's all called 'Name' :-)
sub is_valid_name {
    my ($str, $name) = @_;

    $err = undef;
    $name ||= 'name';

    # check that the name has been given
    unless ( defined $str ) {
        $err = 'Name is undefined';
        return;
    }

    if ( $str eq '' ) {
        $err = 'No name given';
        return;
    }

    unless ( $str =~ m{ \A [a-z0-9][a-z0-9\-]* \z }xms ) {
        $err = "Name must contain only lowercase 'a-z', '0-9', '-' and must start with a letter or a number.";
        return;
    }
    return 1;
}

sub is_min_length {
    my ($str, $min_length, $name) = @_;

    $name ||= 'string';

    unless ( length $str >= $min_length ) {
        $err = "'$name' must be at least $min_length characters long";
        return 0;
    }
    return 1;
}

sub is_max_length {
    my ($str, $max_length, $name) = @_;

    $name ||= 'string';

    unless ( length $str <= $max_length ) {
        $err = "'$name' must be maximum $max_length characters long";
        return 0;
    }
    return 1;
}

sub has_content {
    my ($str, $name) = @_;

    $name ||= 'string';

    unless ( defined $str ) {
        $err = "'$name' is undefined";
        return 0;
    }

    if ( $str eq '' ) {
        $err = "no '$name' given";
        return 0;
    }

    unless ( $str =~ m{ \S }xms ) {
        $err = "'$name' must contain something other than whitespace";
        return 0;
    }

    return 1;
}

sub contains_something {
    my ($str, $name) = @_;

    carp "contains_something(): is deprecated";

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

sub is_datetime {
    my ($dt, $name) = @_;

    warn "dt=$dt, name=$name";

    unless ( $dt =~ m{ \A (\d{4})\-(\d{2})\-(\d{2}) \s (\d{2}):(\d{2}):(\d{2}) \z }xms ) {
        $err = "'$name' must be of the format 'yyyy-mm-dd hh:mm:ss'";
        return;
    }

    warn "dt=$1-$2-$3 $4:$5:$6";

    my $datetime;
    eval {
        $datetime = DateTime->new(
            year   => $1,
            month  => $2,
            day    => $3,
            hour   => $4,
            minute => $5,
            second => $6,
        );
    };
    if ( $@ ) {
        $err = "'$name' doesn't look like a valid date";
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
