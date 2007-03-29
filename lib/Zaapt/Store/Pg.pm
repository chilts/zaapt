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
        if ( m{ \A ts: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$datetime') AS ${letter}_$1";
        } elsif ( m{ \A dt: (.*) \z }xms ) {
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

    @colnames = grep { !m{ \A ts:.* \z }xms } @colnames;
    @colnames = map { m{ \A r:(\w+_id) \z }xms ? $1 : $_ } @colnames;

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

    @colnames = grep { !m{ \A ts:.* \z }xms } @colnames;
    @colnames = map { m{ \A r:(\w+_id) \z }xms ? $1 : $_ } @colnames;

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

sub _mk_count {
    my ($class, $table) = @_;
    return "SELECT count(*) AS count FROM $table";
}

sub _currval {
    my ($self, $seqname) = @_;
    my ($id) = $self->dbh()->selectrow_array( "SELECT currval(?)", undef, $seqname );
    return $id;
}

sub _nextval {
    my ($self, $seqname) = @_;
    my ($id) = $self->dbh()->selectrow_array( "SELECT nextval(?)", undef, $seqname );
    return $id;
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

sub mk_inserter {
    my ($self, $schema, $table, $prefix, @cols) = @_;

    my $sql = __PACKAGE__->_mk_ins( "$schema.$table", @cols );

    my $class = ref $self || $self;
    my $accessor_name = "ins_$table";

    # don't have to check to see if $accessor_name is 'DESTROY' since it never will be

    # get the cols for insertion
    my @cols_sql = @cols;
    @cols_sql = grep { m{ \A ts:(\w+) \z }xms ? 0 : 1 } @cols_sql;
    @cols_sql = map { m{ \A r:(\w+)_id \z }xms ? "_$1" : "${prefix}_$_" } @cols_sql;

    # create the closure
    my $accessor =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, map { $hr->{$_} } @cols_sql );
    };

    # inject into package's namespace
    unless ( defined &{"${class}::$accessor_name"} ) {
        no strict 'refs';
        *{"${class}::$accessor_name"} = $accessor;
    }
}

sub mk_updater {
    my ($self, $schema, $table, $prefix, $id, @cols) = @_;

    my $sql = __PACKAGE__->_mk_upd( "$schema.$table", $id, @cols );

    my $class = ref $self || $self;
    my $accessor_name = "upd_$table";

    # don't have to check to see if $accessor_name is 'DESTROY' since it never will be

    # get the cols for update
    @cols = grep { m{ \A ts:(\w+) \z }xms ? 0 : 1 } @cols;
    @cols = map { m{ \A r:(\w+)_id \z }xms ? "_$1" : "${prefix}_$_" } @cols;

    # create the closure
    my $accessor =  sub {
        my ($self, $hr) = @_;
        my $v = $hr->{"${prefix}_${id}"};
        my @map = map { $hr->{$_} } @cols;
        return $self->_do( $sql, @map, $hr->{"${prefix}_${id}"} );
    };

    # inject into package's namespace
    unless ( defined &{"${class}::$accessor_name"} ) {
        no strict 'refs';
        *{"${class}::$accessor_name"} = $accessor;
    }
}

sub mk_deleter {
    my ($self, $schema, $table, $prefix, $id) = @_;

    # my $sql = "DELETE FROM $schema.$table WHERE $id = ?";
    my $sql = __PACKAGE__->_mk_del("$schema.$table", $id);

    my $class = ref $self || $self;
    my $method_name = "del_$table";

    # don't have to check to see if $method_name is 'DESTROY' since it never will be

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, $hr->{"${prefix}_${id}"} );
    };

    # inject into package's namespace
    unless ( defined &{"${class}::$method_name"} ) {
        no strict 'refs';
        *{"${class}::$method_name"} = $method;
    }
}

sub mk_selecter {
    my ($self, $schema, $table, $prefix, $id, @cols) = @_;

    my $cols = __PACKAGE__->_mk_cols( $prefix, $id, @cols );
    my $sql = "SELECT $cols FROM $schema.$table $prefix WHERE $prefix.$id = ?";

    my $class = ref $self || $self;
    my $method_name = "sel_$table";

    # don't have to check to see if $method_name is 'DESTROY' since it never will be

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_row( $sql, $hr->{"${prefix}_${id}"} );
    };

    # inject into package's namespace
    unless ( defined &{"${class}::$method_name"} ) {
        no strict 'refs';
        *{"${class}::$method_name"} = $method;
    }
}

sub mk_selecter_using {
    my ($self, $schema, $table, $prefix, $col, @cols) = @_;

    my $cols = __PACKAGE__->_mk_cols( $prefix, @cols );
    my $sql = "SELECT $cols FROM $schema.$table $prefix WHERE $prefix.$col = ?";

    my $class = ref $self || $self;
    my $method_name = "sel_${table}_using_${col}";

    # don't have to check to see if $method_name is 'DESTROY' since it never will be

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_row( $sql, $hr->{"${prefix}_${col}"} );
    };

    # inject into package's namespace
    unless ( defined &{"${class}::$method_name"} ) {
        no strict 'refs';
        *{"${class}::$method_name"} = $method;
    }
}

# has side-effects
sub _mk_sql {
    my ($self, $schema, $table) = @_;
    foreach my $t ( values %$table ) {
        # generate some helpful sql while we're here
        $t->{sql_fqt} = "$schema.$t->{name} $t->{prefix}"; # fully qualified table
        $t->{sql_cols} = $self->_mk_cols( $t->{prefix}, @{$t->{cols}} );
    }
}

# injects the accessors into the package's namespace
sub _mk_sql_accessors {
    my ($self, $schema, $table) = @_;
    foreach my $t ( values %$table ) {
        my $last = @{$t->{cols}} - 1;
        __PACKAGE__->mk_inserter( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}}[1..$last] );
        __PACKAGE__->mk_updater( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}} );
        __PACKAGE__->mk_deleter( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}}[0] );
        __PACKAGE__->mk_selecter( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}} );
    }
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
