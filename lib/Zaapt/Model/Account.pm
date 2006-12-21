## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Account;
use base qw( Zaapt::Model );

use strict;
use warnings;

sub model_name { return __PACKAGE__; }

## ----------------------------------------------------------------------------
# methods

# ins_account
# ins_privilege
# ins_role

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Model::Account> - a base class for all implementations of type Account

=head1 METHODS

The following methods should be implemented:

=over

=item

Returns a list of all content sections with associated privileges.

=back

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
