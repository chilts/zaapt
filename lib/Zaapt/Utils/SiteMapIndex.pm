## -------------------------------------------------------------------*-perl-*-
package Zaapt::Utils::SiteMapIndex;

use strict;
use warnings;
use Carp;

use base qw(Class::Accessor);

use XML::Mini::Document;

our $VERSION = '0.1';

sub new {
    my ($class, $args) = @_;

    my $self = {};
    bless $self, ref $class || $class;

    # so far, we have no Sitemaps
    $self->{sitemaps} = [];

    return $self;
}

sub add {
    my ($self, $sitemaps) = @_;
    push @{$self->{sitemaps}}, $sitemaps;
}

sub as_xml {
    my ($self) = @_;

    # make a new XML::Mini::Document and get the root
    my $xml = XML::Mini::Document->new();
    my $root = $xml->getRoot();

    my $hdr = $root->header('xml');
    $hdr->attribute('encoding', 'UTF-8');
    $hdr->attribute('version', '1.0');

    my $sitemapindex = $root->createChild('sitemapindex');
    $sitemapindex->attribute('xmlns', 'http://www.sitemaps.org/schemas/sitemap/0.9');

    foreach my $sitemap ( @{$self->{sitemaps}} ) {
        my $el = $sitemapindex->createChild('sitemap');
        foreach my $key ( keys %$sitemap ) {
            $el->createChild($key)->text( $sitemap->{$key} );
        }
    }

    # return '<?xml version="1.0" encoding="UTF-8"?>', "\n", $xml->toString(), "\n";
    return $xml->toString(), "\n";
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
