## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::News;
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

B<Zaapt::Model::News> - a base class for all implementations of type News

=head1 DATA

The data contained in this model is: News Section and Article. These have the
prefixes respectively as follows: 'n' and 'a'.

=head1 ACCESS RESTRICTIONS

TODO

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
