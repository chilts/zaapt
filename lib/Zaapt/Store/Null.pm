## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Null;
use base qw( Zaapt::Store Class::Accessor );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# implement virtual methods

sub name { return __PACKAGE__; }

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Store::Null> - a base class for all Null models to inherit from

=head1 DESCRIPTION

This content base class and it's derivatives can be used to test your
application in various circumstances.

When passed data of any sort, these classes generally ignore them. If they have
to return a return code, it is usually success of some sort and if they have to
return data, it usually consists of empty lists, empty hashes and/or blank
data.

They just don't do much at all.

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
