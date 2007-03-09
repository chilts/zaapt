## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Menu;
use base qw( Zaapt::Model );

use strict;
use warnings;

sub model_name { return __PACKAGE__; }

## ----------------------------------------------------------------------------
# methods

# see an implementor of this interface to see which methods are required

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Model::Menu> - a base class for all implementations of type Menu

=head1 DATA

There are two types of data in this model, the 'menu' and each 'item'. There
can be many menus and each can contain many items. Any attribute associated
with a menu section, will be returned with a preceeding 'm_'. Any attribute
associated with an item will be returned with a preceeding 'i_'.

Any attribute associated with access restrictions will be returned with a
preceeding '_'.

=head1 METHODS

The following methods should be implemented:

ToDo

=head1 ACCESS RESTRICTIONS

There is VIEW, EDIT and ADMIN. Note, you will need SUPER to be able to CREATE a
new menu.

=item VIEW

If you have 'VIEW' access then you are able to see the menu section and all of
it's items.

=item EDIT

If you have 'EDIT' access then you can add, edit and delete items.

=item ADMIN

If you have 'ADMIN' access then you have the ability to delete this entire menu
section.

=back

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
