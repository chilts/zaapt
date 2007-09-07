## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Dir;
use base qw( Zaapt::Model );

use strict;
use warnings;

sub model_name { return __PACKAGE__; }

## ----------------------------------------------------------------------------
# methods

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Model::Dir> - a base class for all implementations of type Dir

=head1 DATA

The data contained in this model is: Dir and File. These have the prefixes
respectively as follows: qw(d f).

=head1 ACCESS RESTRICTIONS

TODO

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
