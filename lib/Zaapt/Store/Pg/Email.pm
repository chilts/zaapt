## ----------------------------------------------------------------------------
package Zaapt::Store::Pg::Email;
use base qw( Zaapt::Store::Pg Zaapt::Model::Email );

use strict;
use warnings;

use Zaapt::Store::Pg::Account;

## ----------------------------------------------------------------------------
# constants

my $schema = 'email';

my $table = {
    email => {
        name   => 'email',
        prefix => 'e',
        cols   => [
            'id',
            qw(subject text html),
            [ 'type_id', 'fk', 't_id' ],
            qw(isbulk ts:inserted ts:updated),
        ],
    },
    recipient => {
        name   => 'recipient',
        prefix => 'r',
        cols   => [
            'id',
            [ 'email_id', 'fk', 'e_id' ],
            [ 'account_id', 'fk', 'a_id' ],
            qw(issent iserror error),
            qw(ts:inserted ts:updated),
        ],
    },
    info => {
        schema => $schema,
        name => 'info',
        prefix => 'i',
        cols => [
            [ 'account_id', 'fk', 'a_id' ],
            qw(token sent successful rejected ts:inserted ts:updated)
        ],
        pk => [ 'account_id', 'fk', 'a_id' ],
    },
    account => Zaapt::Store::Pg::Account->_get_table( 'account' ),
};

# change the prefix of the imported tables
$table->{account}{prefix} = 'a';

my $join = {
    r_e => "JOIN email.email e ON (r.email_id = e.id)",
    r_a => "JOIN account.account a ON (r.account_id = a.id)",
    a_i => "LEFT JOIN email.info i ON (a.id = i.account_id)",
};

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $table );

# generate the Perl method accessors
__PACKAGE__->_mk_store_accessors( $schema, $table );

## ----------------------------------------------------------------------------
# simple accessors

# set up some useful strings
my $recipient_cols = "$table->{recipient}{sql_sel_cols}, $table->{email}{sql_sel_cols}, $table->{account}{sql_sel_cols}";
my $recipient_joins = "$table->{recipient}{sql_fqt} $join->{r_e} $join->{r_a}";
my $info_cols = "$table->{account}{sql_sel_cols}, $table->{info}{sql_sel_cols}";
my $info_joins = "$table->{account}{sql_fqt} $join->{a_i}";

# email
__PACKAGE__->mk_selecter( $schema, $table->{email}{name}, $table->{email}{prefix}, @{$table->{email}{cols}} );
__PACKAGE__->mk_select_rows( 'sel_email_all', "SELECT $table->{email}{sql_sel_cols} FROM $table->{email}{sql_fqt} ORDER BY e.inserted", [] );
__PACKAGE__->mk_select_rows( 'sel_email_all_bulk', "SELECT $table->{email}{sql_sel_cols} FROM $table->{email}{sql_fqt} WHERE isbulk IS True ORDER BY e.inserted", [] );

# recipient
__PACKAGE__->mk_select_row( 'sel_recipient_next_not_sent', "SELECT $recipient_cols FROM $recipient_joins WHERE issent IS False ORDER BY r.id LIMIT 1", [] );

## ----------------------------------------------------------------------------
# methods

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->_do("DELETE FROM email.info");
    $self->_do("DELETE FROM email.email");
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
