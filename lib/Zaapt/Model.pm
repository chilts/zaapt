## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model;

use strict;
use warnings;

our $VERSION = '0.1';

sub model_name {
    die "Zaapt::Model::model_name(): should be implemented";
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
