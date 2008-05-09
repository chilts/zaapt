## -------------------------------------------------------------------*-perl-*-
package Zaapt;

use strict;
use warnings;
use Carp;

our $VERSION = '0.1';

sub new {
    my ($class, $args) = @_;

    my $self = {};
    bless $self, ref $class || $class;

    # remember certain args
    # - store: 'Pg', 'MySQL'
    # - dbh: a DBI object (like from DBD::Pg)
    # - map: a mapping of names to packages
    foreach ( qw(store map dbh) ) {
        $self->{$_} = $args->{$_}
            if defined $args->{$_};
    }

    # so far, we have no models
    $self->{models} = {};

    return $self;
}

sub dbh {
    my ($self) = @_;
    return $self->{dbh};
}

sub start_tx {
    my ($self) = @_;
    $self->dbh->begin_work();
}

sub commit_tx {
    my ($self) = @_;
    $self->dbh->commit();
}

sub rollback_tx {
    my ($self) = @_;
    $self->dbh->rollback();
}

sub get_model {
    my ($self, $model) = @_;

    # return it if we already have it
    return $self->{models}{$model} if exists $self->{models}{$model};

    # see if there is a mapping for this $model
    if ( exists $self->{map}{$model} ) {
        eval "use $self->{map}{$model}";
        if ( $@ ) {
            die "Couldn't load Model '$self->{map}{$model}' module: $@";
        }
        $self->{models}{$model} = "$self->{map}{$model}"->new({ dbh => $self->{dbh} });
        $self->{models}{$model}->parent( $self );
    }

    # or create one if just a name
    elsif ( $model =~ m{ \A \w+ \z }xms ) {
        eval "use Zaapt::Store::$self->{store}::$model";
        if ( $@ ) {
            die "Couldn't load Model 'Zaapt::Store::$self->{store}::$model' module: $@";
        }
        $self->{models}{$model} = "Zaapt::Store::$self->{store}::$model"->new({ dbh => $self->{dbh} });
        $self->{models}{$model}->parent( $self );
    }

    # or create one from the '$model'
    elsif ( $model =~ m{ \A \w+(::\w+)* \z }xms ) {
        eval "use $model";
        if ( $@ ) {
            die "Couldn't load Model '$model' module: $@";
        }
        $self->{models}{$model} = $model->new({ dbh => $self->{dbh} });
        $self->{models}{$model}->parent( $self );
    }
    else {
        warn "Unknown model: '$model'";
    }
    return $self->{models}{$model};
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt> - a small lightweight CMS written in Perl/Mason using PostgreSQL

=head1 SYNOPSIS

    use Zaapt;

    # create a Zaapt instance, passing it the DBH and telling it the store to use
    $zaapt = Zaapt->new({
        store => 'Pg',
        dbh => $dbh,
    });

    # get an instance of the model that represents the 'Content'
    $model = $zaapt->get_model('Content');

    # get the information for the content section named 'home'
    $content = $model->sel_content_using_name({ c_name => 'home' });

    # get the info for the page named 'index' with the 'home' section
    $page = $content_model->sel_page_using_name({
        c_id   => $content->{c_id},
        p_name => 'index',
    });

=head1 DESCRIPTION

The $zaapt instance you create helps you interface with the models that Zaapt
has to offer. Usually you use it to then retrieve an instance which helps you
interface with a particular model.

Zaapt model interfaces has a simple but consistent way of dealing with
data. Instance methods are not used to access data since no objects that
represent data are returned, instead normal Perl data structures are
returned. This may not sound ideal for interface purposes but it works rather
well.

See L<Zaapt::Model> for further information.

=head1 Methods

=over 4

=item Zaapt->new()

Creates a new instance of the Zaapt module. Allows interaction with all of the
models within Zaapt.

Takes a hashref which can contain a number of different keys.

=head3 dbh => $dbh

The 'dbh' key is the DBI::* connection to the database.

=head3 store => 'Pg'

The 'store' parameter is the Zaapt::Store::* name which will be used to talk to
the store. Currently on Pg is defined.

=head3 map => { Something => 'Path::To::Something' }

The 'map' parameter is a hashref which defines which Zaapt::Store::Pg::* module
to use. In reality, this mapping is automatic but this can be used if you have
your own content models in your
website. e.g. KapitiGeekNZ::Zaapt::Store::Pg::Something.

    $zaapt = Zaapt->new({
        store => 'Pg',
        dbh   => $dbh,
        map   => {
            Something => 'KapitiGeekNZ::Zaapt::Store::Pg::Something',
        },
    });

This will retrieve the correct model when you just ask for 'Something':

    $something = $zaapt->get_model('Something');

NOTE: this should really pass the things passed in (ie. $dbh) to the
appropriate Zaapt::Store::* which is then used instead of the raw $dbh which is
not necessarily going to be available with all stores.

=item $zaapt->get_model($str)

This takes a string and tries to map it onto a model.

If the string exists in the previously passed in 'map' hash reference, it tried
to create an instance of that value and returns it.

    $something = $zaapt->get_model('Something');

Returns an object of type KapitiGeekNZ::Zaapt::Store::Pg::Something.

If the string looks just like a normal name (consists of only letters), it
tries to return a standard Zaapt model:

    $account = $zaapt->get_model('Account');

Returns an object of type Zaapt::Store::Pg::Account.

If the string looks like a module name (it has :: in it somewhere), it tries to
return a model with the same name:

    $vlog = $zaapt->get_model('Elsewhere::Zaapt::Store::Pg::Vlog');

Returns an object of type Elsewhere::Zaapt::Store::Pg::Vlog.

=item $zaapt->start_tx()

Starts a transaction in the back-end store.

Currently, this just starts a transaction in the $dbh passed in when this
instance was created.

NOTE: it really should just delegate to the $store instance and call start_tx()
on that.

=item $zaapt->commit_tx()

Commits the transaction in the back-end store.

Currently, this just commits the transaction in the $dbh passed in when this
instance was created.

NOTE: it really should just delegate to the $store instance and call
commit_tx() on that.

=item $zaapt->rollback_tx()

Rolls back the transaction in the back-end store.

Currently, this just rolls back the transaction in the $dbh passed in when this
instance was created.

NOTE: it really should just delegate to the $store instance and call
rollback_tx() on that.

=item $zaapt->dbh()

Returns the $dbh originally passed in when this $zaapt instance was created.

NOTE: will be deprecated in favour of a 'store' method.

=back

=head1 LINKS

Project page : http://code.google.com/p/zaapt/

Git repo     : http://git.kapiti.geek.nz/?p=zaapt.git

=head1 SUPPORT

There are some groups which can help with this set of modules. The main one is
the Google Groups group zaapt-discuss. For a Subversion commit list see
zaapt-commit. For notification of issues see zaapt-issue.

Bugs may be posted at: http://code.google.com/p/zaapt/issues/list

=head1 SEE ALSO

L<Zaapt::Model>, L<Zaapt::Store>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Andrew Chilton B<E<lt>andychilton@gmail.comE<gt>>

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
