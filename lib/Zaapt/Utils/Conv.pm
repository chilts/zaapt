## -------------------------------------------------------------------*-perl-*-
package Zaapt::Utils::Conv;

use strict;
use warnings;

our $VERSION = '0.1';

my $true_values = {
    checked => 1,
    on => 1,
    yes => 1,
    true => 1,
    '1' => 1,
};

my $err;

sub err {
    return $err;
}

sub to_bool {
    my ($arg) = @_;
    $arg = lc $arg;
    return exists $true_values->{$arg} ? '1' : '0';
}

sub remove_cr {
    my ($arg) = @_;
    $arg =~ s{\r}{}gxms;
    return $arg;
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Utils::Conv> - just some really small but useful routines

=head1 AUTHOR

Contact: Andrew Chilton B<E<lt>andychilton@gmail.comE<gt>>

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
