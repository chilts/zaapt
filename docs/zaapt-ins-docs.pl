#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use File::Glob ':glob';
use File::Slurp;
use Text::Phliky;
use DBI;
use Zaapt;

my $DEBUG = 0;

# setup some variables
my $c_name = 'docs';
my $t_name = 'phliky';
my $db_host = undef;
my $db_name = 'zaapt-demo';
my $db_user = 'zaapt-demo';
my $db_pass = undef;

# connect to the database
my $dbh = DBI->connect(
    "dbi:Pg:dbname=$db_name",
    $db_user,
    $db_pass,
    { RaiseError => 1, AutoCommit => 1 }
);

# create Zaapt
my $zaapt = Zaapt->new({ store => 'Pg', dbh => $dbh });
my $model = $zaapt->get_model('Content');
my $contents = $model->sel_content_all();
my $type = $zaapt->get_model('Common')->sel_type_using_name({ t_name => $t_name });

print Data::Dumper->Dump([$contents], ['c']) if $DEBUG;

my $content = $model->sel_content_using_name({ c_name => $c_name });

unless ( defined $content ) {
    print STDERR "Content section '$c_name' doesn't exist\n";
    exit 2;
}

unless ( defined $type ) {
    print STDERR "Type '$t_name' doesn't exist\n";
    exit 2;
}

# find all files to insert/update
my @filenames = bsd_glob('*.flk');

foreach my $filename ( @filenames ) {
    my ($name, $path, $suffix) = fileparse($filename, '.flk');

    print "Page '$name'...\n";

    my $page_content = read_file( $filename );

    unless ( defined $content ) {
        print "- content is not defined\n";
        next;
    }

    # see if this name already exists
    my $page = $model->sel_page_using_name({ c_id => $content->{c_id}, p_name => $name});
    if ( defined $page ) {
        print "- $name already exists\n";
        $model->upd_page({
            c_id      => $content->{c_id},
            t_id      => $type->{t_id},
            p_id      => $page->{p_id},
            p_name    => $name,
            p_content => $page_content,
        });
    }
    else {
        print "- $name does not exist\n";
        $model->ins_page({
            c_id      => $content->{c_id},
            t_id      => $type->{t_id},
            p_name    => $name,
            p_content => $page_content,
        });
    }
}
