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

sub trim {
	my ($arg) = @_;
    return unless defined $arg;
    $arg =~ s{ \A \s+ }{}gxms;
    $arg =~ s{ \s+ \z }{}gxms;
	return $arg;
}

sub crunch {
	my ($arg) = @_;
    return unless defined $arg;
    $arg =~ s{ \A \s+ }{}gxms;
    $arg =~ s{ \s+ \z }{}gxms;
    $arg =~ s{ \s+ }{\ }gxms;
	return $arg;
}

sub namify {
    my ($arg) = @_;

    # try and do some funky things
    my $name = crunch($arg);         # crunch whitespace to 1
    $name =~ s{\b&\b}{and}gxms;      # special stuff for '&'
    $name =~ s{[\'\"]}{}gxms;        # remove quotes
    $name =~ s{[^A-Za-z0-9]}{-}gxms; # anything note a 'word' char, replace with '-'
    $name =~ s{\A-+}{}gxms;          # remove multiple -'s at start
    $name =~ s{-+\z}{}gxms;          # remove multiple -'s at end
    $name =~ s{-+}{-}gxms;           # crunch multiple -'s to 1 '-'
    return lc $name;                 # lowercase and finish up!
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
