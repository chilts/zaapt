## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Plugin;
use base qw( Zaapt::Model );

use strict;
use warnings;

sub model_name { return __PACKAGE__; }

## ----------------------------------------------------------------------------
# methods

# _nuke

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Model::Plugin> - a base class for all implementations of type Plugin

=head1 DATA

There are: p - plugin, s - setting.

=head1 INFO

ToDo: info.

=head1 ACCESS RESTRICTIONS

ToDo: access restrictions.

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
