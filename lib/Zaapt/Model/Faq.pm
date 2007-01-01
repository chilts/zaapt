## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Faq;
use base qw( Zaapt::Model );

use strict;
use warnings;

sub model_name { return __PACKAGE__; }

## ----------------------------------------------------------------------------
# methods

# ins_content
# sel_all_content
# del_content_where
# ins_page
# sel_all_pages_in
# sel_page_with_name
# upd_page_where
# del_page_where
# sel_page_where
# sel_all_pages
# _nuke

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Model::Faq> - a base class for all implementations of type Faq

=head1 DATA

There are two types of data in this model, the 'Faq' itself and each
'question'. There can be many Faqs and each can contain many questions. Any
attribute associated with an Faq section will be returned with a preceeding
'f_'. Any attribute assocaited with a page will be returned with a preceeding
'q_'.

Any attribute associated with access restrictions will be returned with a
preceeding '_' as usual.

=head1 METHODS

The following methods should be implemented:

=over

=item sel_faq_all

Returns a list of all Faq sections with associated privileges.

 e.g. $faqs = [
     { f_name => 'sect1', _view => 1, _page => 1, _publish => 0, _admin => 0 },
     { f_name => 'sect2', _view => 1, _page => 1, _publish => 1, _admin => 0 },
 ];

=back

=head1 ACCESS RESTRICTIONS

TODO

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
