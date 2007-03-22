## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model;

use strict;
use warnings;
use Scalar::Util qw(weaken);

our $VERSION = '0.1';

sub model_name {
    die "Zaapt::Model::model_name(): should be implemented";
}

sub parent {
    my $self = shift;
    @_ ? weaken($self->{parent} = shift) : $self->{parent};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Model> - a base class for all models to inherit from

=head1 ABOUT

This package has no functionality except to be a base class for all models.

=head1 AUTHOR

Contact: Andrew Chilton B<E<lt>andychilton@gmail.comE<gt>>

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
