## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Gallery;
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

B<Zaapt::Model::Gallery> - a base class for all implementations of type Gallery

=head1 DATA

The data contained in this model is: Gallery, Picture, Field, Detail and
Size. These have the prefixes respectively as follows: qw(g p f d s).

=head1 ACCESS RESTRICTIONS

TODO

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
