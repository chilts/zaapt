## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Friend;
use base qw( Zaapt::Store::Pg Zaapt::Model::Friend );

use strict;
use warnings;

use Zaapt::Store::Pg::Account;

## ----------------------------------------------------------------------------
# constants

my $schema = 'friend';

my $table = {
    friend => {
        schema => $schema,
        name   => 'friend',
        prefix => 'f',
        cols   => [
            'id',
            [ 'account_id', 'fk', 'a_id' ],
            [ 'to_id', 'fk', 't_id' ],
            qw(ts:inserted ts:updated) ],
    },
    account => Zaapt::Store::Pg::Account->_get_table( 'account' ),
    to => Zaapt::Store::Pg::Account->_get_table( 'account' ),
};

# change the prefix of the imported tables
$table->{to}{prefix} = 't';

my $join = {
    f_a   => "JOIN account.account a ON (f.account_id = a.id)",
    f_t  => "JOIN account.account t ON (f.to_id = t.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $table );

## ----------------------------------------------------------------------------

# set up some useful strings
my $friend_cols = "$table->{friend}{sql_sel_cols}, $table->{account}{sql_sel_cols}, $table->{to}{sql_sel_cols}";
my $friend_joins = "$table->{friend}{sql_fqt} $join->{f_a} $join->{f_t}";

# friend
__PACKAGE__->mk_selecter_from( $schema, $table->{friend} );

# get all friends
__PACKAGE__->mk_select_rows( 'sel_friend_all', "SELECT $friend_cols FROM $friend_joins ORDER BY f.id", [] );

# get all your friends
__PACKAGE__->mk_select_rows( 'sel_friend_for', "SELECT $friend_cols FROM $friend_joins WHERE a.id = ? ORDER BY t.username", [ 'a_id' ] );

# get everyone who considers you as a friend
__PACKAGE__->mk_select_rows( 'sel_friend_to', "SELECT $friend_cols FROM $friend_joins WHERE t.id = ? ORDER BY a.username", [ 't_id' ] );

# get this specific pair
__PACKAGE__->mk_select_row( 'sel_friend_pair', "SELECT $friend_cols FROM $friend_joins WHERE a.id = ? AND t.id = ?", [ 'a_id', 't_id' ]);

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM friend.friend");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
