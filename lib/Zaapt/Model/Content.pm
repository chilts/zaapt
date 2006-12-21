## -------------------------------------------------------------------*-perl-*-
package Zaapt::Model::Content;
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

B<Zaapt::Model::Content> - a base class for all implementations of type Content

=head1 DATA

There are two types of data in this model, the 'content' and the 'page'. There
can be many contents and each can contain many pages. Any attribute associated
with a content section, will be returned with a preceeding 'c_'. Any attribute
associated with a page will be returned with a preceeding 'p_'.

Any attribute associated with access restrictions will be returned with a
preceeding '_'.

=head1 METHODS

The following methods should be implemented:

=over

=item sel_content_all

Returns a list of all content sections with associated privileges.

 e.g. $contents = [
     { c_name => 'main', _view => 1, _page => 1, _publish => 0, _admin => 0 },
     { c_name => 'about', _view => 1, _page => 1, _publish => 1, _admin => 0 },
 ];

=item ins_section

Takes a hash of values which should contain the keys 'c_name', '_view',
'_page', '_publish', '_admin'. Alternately, you may pass the '_default' key
which will be used as a replacement for any '_*' key not given.

 e.g. $content->ins_section({ c_name => 'main', _view => 'marketing', _default => 'editor' });

This gives view access to anyone with the 'marketing' role and allows the
'editor' to do anything else to the content.

=back

=head1 ACCESS RESTRICTIONS

To illustrate these restrictions, here is an example.

Tom is allowed to edit content posts. His is a content-editor. He cannot create pages.

Miranda though is allowed to create AND edit posts. She is a content-creator AND content-editor.

Jane has total editing privileges so she just has the role 'editor', which includes publishing.

Janet has publishing privileges.

Therefore, a content (top level) has the following roles:

 ADMIN   : editor
 VIEW    : content-home-view
 CREATE  : content-home-create
 EDIT    : content-home-edit
 PUBLISH : content-home-editor

So Tom has been assigned 'content-home-view' and 'content-home-edit'.

Miranda has content-home-view, content-home-create, content-home-edit.

Jane has editor.

Janet has content-home-view and content-home-edit.


Access restrictions are given on a Content section level. There are 4 access
restrictions which can be adhered to. They are:

=over

=item view

If you have 'view' access then you are able to see the content section and all
of it's pages (even unpublished ones).

=item page

If you have 'page' access then you can add, edit and delete pages.

=item publish

If you have 'publish' access then you can publish and unpublish pages.

=item admin

If you have 'admin' access then you have the ability to delete this entire
content section.

=back

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
