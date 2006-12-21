## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store;

use strict;
use warnings;

our $VERSION = '0.1';

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Store> - a base class for all stores to inherit from

=head1 METHODS

Currently there is only one method which is required to be implemented by
inheriting classes:

=over

=item store_name

Returns the name of the inheriting store.

=back

=head1 NOTES

It is not up to the store to figure out if this user has permission to do the
things asked of it. The stores are simple objects and do what they are told. It
is up to the controllers to figure out who can do what, if indeed there is any
restriction at all, or a really tight one.

The stores (in fact the models) can advertise what privileges are required for
viewing or editing this instance of the model.

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
