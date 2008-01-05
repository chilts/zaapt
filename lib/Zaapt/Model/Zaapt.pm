## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Zaapt;
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

B<Zaapt::Model::Zaapt> - a base class for all implementations of type Zaapt

=head1 DATA

There are two types of data in this model, the 'model' and each
'setting'. Each model contains 0 or more settings.

=head1 ACCESS RESTRICTIONS

TODO

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
