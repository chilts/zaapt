## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Forum;
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

B<Zaapt::Model::Forum> - a base class for all implementations of type Forum

=head1 DATA

The data contained in this model is: Forum, Topic, Post. Prefixes 'f', 't' and
'p' respectively.

=head1 ACCESS RESTRICTIONS

TODO

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
