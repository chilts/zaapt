## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Message;
use base qw( Zaapt::Store::Pg Zaapt::Model::Message );

use strict;
use warnings;

use Zaapt::Store::Pg::Account;

## ----------------------------------------------------------------------------
# constants

my $schema = 'message';

my $table = {
    message => {
        schema => $schema,
        name   => 'message',
        prefix => 'm',
        cols   => [
            'id',
            [ 'account_id', 'fk', 'a_id' ],
            [ 'to_id', 'fk', 't_id' ],
            qw(subject message read ts:inserted ts:updated) ],
    },
    account => Zaapt::Store::Pg::Account->_get_table( 'account' ),
    to => Zaapt::Store::Pg::Account->_get_table( 'account' ),
};

# change the prefix of the imported tables
$table->{to}{prefix} = 't';

my $join = {
    m_a   => "JOIN account.account a ON (m.account_id = a.id)",
    m_t  => "JOIN account.account t ON (m.to_id = t.id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $table );

## ----------------------------------------------------------------------------
# simple accessors

# set up some useful strings
my $message_cols = "$table->{message}{sql_sel_cols}, $table->{account}{sql_sel_cols}, $table->{to}{sql_sel_cols}";
my $message_joins = "$table->{message}{sql_fqt} $join->{m_a} $join->{m_t}";

# get this message (and other important info)
__PACKAGE__->mk_select_row( 'sel_message', "SELECT $message_cols FROM $message_joins WHERE m.id = ?", [ 'm_id' ] );

# get all your NEW messages
__PACKAGE__->mk_select_rows( 'sel_message_all_new', "SELECT $message_cols FROM $message_joins WHERE m.to_id = ? AND m.read IS False ORDER BY m.inserted DESC", [ 't_id' ] );

# get your READ messages
__PACKAGE__->mk_select_rows( 'sel_message_all_read', "SELECT $message_cols FROM $message_joins WHERE m.to_id = ? AND m.read IS True ORDER BY m.inserted DESC", [ 't_id' ] );

# get all your SENT messages
__PACKAGE__->mk_select_rows( 'sel_message_all_from', "SELECT $message_cols FROM $message_joins WHERE m.account_id = ? ORDER BY m.inserted DESC", [ 'a_id' ] );

# get ALL of your messages regardless
__PACKAGE__->mk_select_rows( 'sel_message_all_for', "SELECT $message_cols FROM $message_joins WHERE m.account_id = ? OR m.to_id = ? ORDER BY m.inserted DESC", [ 'a_id', 'a_id' ]);

# get a summary of all your messages

# NEW messages
__PACKAGE__->mk_select_row( 'sel_message_count_new', "SELECT count(*) AS _count FROM message.message WHERE to_id = ? AND read IS False", [ 't_id' ] );

# READ messages
__PACKAGE__->mk_select_row( 'sel_message_count_read', "SELECT count(*) AS _count FROM message.message WHERE to_id = ? AND read IS True", [ 't_id' ] );

# SENT messages
__PACKAGE__->mk_select_row( 'sel_message_count_sent', "SELECT count(*) AS _count FROM message.message WHERE account_id = ?", [ 'a_id' ] );

# ALL messages
__PACKAGE__->mk_select_row( 'sel_message_count_all', "SELECT count(*) AS _count FROM message.message WHERE account_id = ? OR to_id = ?", [ 'a_id', 'a_id' ]);

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM message.message");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
