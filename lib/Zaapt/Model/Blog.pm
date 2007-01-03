## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Blog;
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

B<Zaapt::Model::Blog> - a base class for all implementations of type Blog

=head1 DATA

The data contained in this model is: Blog, Entry, Comment and Trackback. These
have the prefixes respectively as follows: 'b', 'e', 'c' and t'. There is also
the label and type tables but they are under L<Zaapt::Model::Common>.

=head1 ACCESS RESTRICTIONS

TODO

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
