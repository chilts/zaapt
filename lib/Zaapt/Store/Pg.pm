## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg;
use base qw( Zaapt::Store Class::Accessor );

use strict;
use warnings;

our $VERSION = '0.1';

__PACKAGE__->mk_accessors( qw(dbh) );

## ----------------------------------------------------------------------------
# globals

my $date = 'YYYY-MM-DD';
my $time = 'HH24:MI:SS';
my $datetime = "$date $time";

## ----------------------------------------------------------------------------
# implement virtual methods

sub store_name { return __PACKAGE__; }

## ----------------------------------------------------------------------------
# helper methods

sub _mk_cols {
    my ($class, $letter, @colnames) = @_;
    return '' unless @colnames;

    my $first = shift @colnames;
    my $cols = "$letter.$first AS ${letter}_$first";

    foreach ( @colnames ) {
        if ( m{ \A dt: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$datetime') AS ${letter}_$1";
        } elsif ( m{ \A d: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$date') AS ${letter}_$1_date";
        } elsif ( m{ \A t: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$time') AS ${letter}_$1_time";
        } elsif ( m{ \A r: (.*) \z }xms ) {
            my $col = $1;
            # getting a role
            my ($role) = $col =~ m{ \A (\w*) \_id \z }xms;
            $cols .= ", $letter.$col AS _$1";
        } else {
            $cols .= ", $letter.$_ AS ${letter}_$_";
        }
    }
    return $cols;
}

sub _mk_sel {
    my ($class, $table, $letter, @colnames) = @_;
    return '' unless @colnames;

    my $cols;
    foreach my $colname ( @colnames ) {
        $cols .= ", " if defined $cols;
        $cols .= "$colname AS ${letter}_${colname}";
    }

    return "SELECT $cols FROM $table $letter WHERE id = ?";
}

sub _mk_sel_where {
    my ($class, $table, $letter, $where_h, @colnames) = @_;
    return '' unless @colnames;

    my $cols;
    foreach my $colname ( @colnames ) {
        $cols .= ", " if defined $cols;
        $cols .= "$colname AS ${letter}_${colname}";
    }

    my $sql = "SELECT $cols FROM $table $letter";

    if ( defined $where_h and %$where_h ) {
        my $where = '';
        foreach my $col ( keys %$where_h ) {
            $where .= ' AND ' if $where;
            $where .= "$letter.$col = ?";
        }
        $sql .= " WHERE $where";
    }

    return $sql;
}

sub _mk_ins {
    my ($class, $table, @colnames) = @_;
    return '' unless @colnames;

    my $cols = shift @colnames;
    my $qs = '?';
    foreach my $colname ( @colnames ) {
        $cols .= ", $colname";
        $qs .= ', ?';
    }

    return "INSERT INTO $table($cols) VALUES($qs)";
}

sub _mk_upd {
    my ($class, $table, $pk, @colnames) = @_;
    return '' unless @colnames;

    my $colname = shift @colnames;
    my $cols = "$colname = COALESCE(?, $colname)";
    foreach my $colname ( @colnames ) {
        $cols .= ", $colname = COALESCE(?, $colname)";
    }

    return "UPDATE $table SET $cols WHERE $pk = ?";
}

sub _mk_del {
    my ($class, $table, @colnames) = @_;
    return '' unless @colnames;

    my $query = shift(@colnames) . " = ?";
    foreach my $colname ( @colnames ) {
        $query .= " AND $colname = ?";
    }

    return "DELETE FROM $table WHERE $query";
}

sub _do {
    my ($self, $stm, @bind_values) = @_;
    return $self->dbh()->do( $stm, undef, @bind_values );
}

sub _rows {
    my ($self, $stm, @bind_values) = @_;
    my $sth = $self->get_sth( $stm );
    my $rows = [];
    $sth->execute( @bind_values );
    while ( my $row = $sth->fetchrow_hashref() ) {
        push @$rows, $row;
    }
    $sth->finish();
    return $rows;
}

sub _row {
    my ($self, $stm, @bind_values) = @_;
    my $sth = $self->get_sth( $stm );
    $sth->execute( @bind_values );
    my $row = $sth->fetchrow_hashref();
    $sth->finish();
    return $row;
}

## ----------------------------------------------------------------------------
# methods

sub get_sth {
    my ($self, $stm) = @_;
    return $self->{dbh}->prepare_cached( $stm );
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
=pod

=head1 NAME

B<Zaapt::Store::Pg> - a base class for all PostgreSQL models to inherit from

=head1 SYNOPSIS

 use base qw( Zaapt::Store::Pg Zaapt::Model::Account );

 # table names
 my $account_tablename = "account a";

 # column lists
 my $account_cols = __PACKAGE__->_mk_cols( 'a', qw(id username firstname lastname email) );

 # SQL
 my $ins_account = __PACKAGE__->_mk_ins( 'account', qw(username firstname lastname email) );
 my $upd_account = __PACKAGE__->_mk_upd( 'account', 'id', qw(username firstname lastname email) );
 my $del_content = __PACKAGE__->_mk_del( 'account', 'id' );
 my $sel_content = __PACKAGE__->_mk_sel( 'account', { id => 1 }, qw(id username firstname lastname email) );
 my $sel_account_all = "SELECT $account_cols FROM $account_tablename ORDER BY a.username";
 my $sel_account_for_username = "SELECT $account_cols FROM $account_tablename WHERE username = ?";

=head1 HELPER METHODS

=over

=item set_sql

Pass it a name and some sql and the object will remember the SQL.

=back

=head1 VIRTUAL METHODS

Currently there is only one method which is required to be implemented by
inheriting classes:

=over

=item recreate_sql

Recreates the SQL.

=back

=head1 SEE ALSO

L<Zaapt>, L<Zaapt::Model>, L<Zaapt::Store>

=cut
