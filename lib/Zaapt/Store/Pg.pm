## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg;
use base qw( Zaapt::Store Class::Accessor );

use strict;
use warnings;
use Carp;
use List::Util qw(reduce);

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

sub _get_table {
    my ($class, $tablename) = @_;
    my $tables = $class->_get_tables();
    return unless exists $tables->{$tablename};
    return $tables->{$tablename};
}

sub _mk_cols {
    my ($class, $letter, @colnames) = @_;
    warn "_mk_cols() is deprecated, use _mk_sel_cols() instead";
    return '' unless @colnames;

    my $first = shift @colnames;
    my $cols = "$letter.$first AS ${letter}_$first";

    foreach ( @colnames ) {
        if ( m{ \A ts: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$datetime') AS ${letter}_$1";
        } elsif ( m{ \A dt: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$datetime') AS ${letter}_$1";
        } elsif ( m{ \A d: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$date') AS ${letter}_$1";
        } elsif ( m{ \A t: (.*) \z }xms ) {
            $cols .= ", to_char($letter.$1, '$time') AS ${letter}_$1";
        } elsif ( m{ \A ro: (.*) \z }xms ) {
            $cols .= ", $letter.$1 AS ${letter}_$1";
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

sub _mk_sel_col {
    my ($class, $prefix, $col) = @_;

    if ( ref $col eq 'ARRAY' ) {
        my $type = $col->[1];
        if ( $type eq 'virtual' ) {
            return "$col->[2] AS ${prefix}_$col->[0]";
        }
        if ( $type eq 'fk' ) {
            return "${prefix}.$col->[0] AS ${prefix}_$col->[0]";
        }
        croak "Unknown column type '$col->[0]'";
    }

    if ( $col =~ m{ \A ts: (.*) \z }xms ) {
        return "to_char($prefix.$1, '$datetime') AS ${prefix}_$1";
    }

    if ( $col =~ m{ \A dt: (.*) \z }xms ) {
        return "to_char($prefix.$1, '$datetime') AS ${prefix}_$1";
    }

    if ( $col =~ m{ \A d: (.*) \z }xms ) {
        return "to_char($prefix.$1, '$date') AS ${prefix}_$1";
    }

    if ( $col =~ m{ \A t: (.*) \z }xms ) {
        return "to_char($prefix.$1, '$time') AS ${prefix}_$1";
    }

    if ( $col =~ m{ \A ro: (.*) \z }xms ) {
        return "$prefix.${1} AS ${prefix}_$1";
    }

    if ( $col =~ m{ \A r: (.*)_id \z }xms ) {
        return "$prefix.${1}_id AS _$1";
    }

    return "$prefix.$col AS ${prefix}_$col";
}

sub _mk_sel_cols {
    my ($class, $prefix, @cols) = @_;
    return '' unless @cols;

    my $first = shift @cols;
    my $sql = $class->_mk_sel_col( $prefix, $first );

    foreach my $col ( @cols ) {
        $sql .= ", " . $class->_mk_sel_col( $prefix, $col );
    }
    return $sql;
}

sub _mk_sel {
    my ($class, $table, $prefix, @colnames) = @_;
    return '' unless @colnames;

    my $cols;
    foreach my $colname ( @colnames ) {
        $cols .= ", " if defined $cols;
        $cols .= "$colname AS ${prefix}_${colname}";
    }

    return "SELECT $cols FROM $table $prefix WHERE id = ?";
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
    @colnames = grep { !m{ \A ro: }xms } @colnames;
    @colnames = map { m{ \A (\w+):(\w+) \z }xms ? $2 : $_ } @colnames;

    my $cols = shift @colnames;
    my $qs = '?';
    foreach my $colname ( @colnames ) {
        $cols .= ", $colname";
        $qs .= ', ?';
    }

    return "INSERT INTO $table($cols) VALUES($qs)";
}

sub _mk_col_names {
    my ($class, $t, @cols) = @_;
    return '' unless @cols;

    my $colnames = ();

    foreach my $col ( @cols ) {
        # skip if the primary key
        next if $col eq 'id';
        next if ( defined $t->{pk} and ref $col and $col->[0] eq $t->{pk}[0] );

        # skip if field is read-only (timestamp included)
        next if $col =~ m{ \A ts: }xms;
        next if $col =~ m{ \A ro: }xms;

        # process the rest
        if ( $col =~ m{ \A r:(\w+_id) \z }xms )  {
            push @$colnames, $1;
            next;
        }
        if ( $col =~ m{ \A (\w+):(\w+) \z }xms )  {
            push @$colnames, $2;
            next;
        }
        if ( ref $col eq 'ARRAY' ) {
            next if $col->[1] eq 'virtual';
            push @$colnames, $col->[0];
            next;
        }
        push @$colnames, $col;
    }

    return $colnames;
}

sub _mk_ins_cols {
    my ($class, $prefix, @cols) = @_;
    return '' unless @cols;

    my @colnames = ();

    foreach my $col ( @cols ) {
        next if $col eq 'id';
        next if $col =~ m{ \A ts: }xms;
        next if $col =~ m{ \A ro: }xms;
        if ( $col =~ m{ \A r:(\w+_id) \z }xms )  {
            push @colnames, $1;
            next;
        }
        if ( $col =~ m{ \A (\w+):(\w+) \z }xms )  {
            push @colnames, $2;
            next;
        }
        if ( ref $col eq 'ARRAY' ) {
            next if $col->[1] eq 'virtual';
            push @colnames, $col->[0];
            next;
        }
        push @colnames, $col;
    }

    my $cols = reduce { "$a, $b" } @colnames;
    # my $qs = '?' . (', ?' x $#colnames);

    return $cols;
}

sub _mk_qm {
    my ($class, @cols) = @_;

    return '' unless @cols;

    my @colnames = ();

    foreach my $col ( @cols ) {
        next if $col eq 'id';
        next if $col =~ m{ \A ts: }xms;
        next if $col =~ m{ \A ro: }xms;
        next if ( ref $col eq 'ARRAY' and $col->[1] eq 'virtual' );
        push @colnames, $col;
    }

    my $qs = '?' . (', ?' x $#colnames);

    return $qs;
}

sub _mk_upd {
    my ($class, $table, $pk, @colnames) = @_;
    return '' unless @colnames;

    @colnames = grep { !m{ \A ts:.* \z }xms } @colnames;
    @colnames = map { m{ \A r:(\w+_id) \z }xms ? $1 : $_ } @colnames;
    @colnames = grep { !m{ \A ro: }xms } @colnames;
    @colnames = map { m{ \A (\w+):(\w+) \z }xms ? $2 : $_ } @colnames;

    my $colname = shift @colnames;
    my $cols = "$colname = COALESCE(?, $colname)";
    foreach my $colname ( @colnames ) {
        $cols .= ", $colname = COALESCE(?, $colname)";
    }

    return "UPDATE $table SET $cols WHERE $pk = ?";
}

sub _mk_upd_cols {
    my ($class, $t) = @_;
    my @cols = @{$t->{cols}};
    return '' unless @cols;

    my $colnames = $class->_mk_col_names( $t, @cols );

    $colnames->[0] = "$colnames->[0] = COALESCE(?, $colnames->[0])";
    my $sql .= reduce { "$a, $b = COALESCE(?, $b)" } ( @$colnames );

    return $sql;
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

# for 'make hashref names' - in the hash being passed to all the functions
sub _mk_hr_names {
    my ($class, $prefix, @cols) = @_;

    my @names = ();

    foreach my $col ( @cols ) {
        next if $col =~ m{ \A ts: }xms;
        next if $col =~ m{ \A ro: }xms;
        if ( $col =~ m{ \A r:(\w+)_id \z }xms ) {
            push @names, "_$1";
            next;
        }
        if ( $col =~ m{ \A (\w+):(\w+) \z }xms ) {
            push @names, "${prefix}_$2";
            next;
        }
        if ( ref $col eq 'ARRAY' ) {
            next if $col->[1] eq 'virtual';
            push @names, $col->[2] if $col->[1] eq 'fk';
            next;
        }
        push @names, "${prefix}_${col}";
    }

    return @names;
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
    my ($self, $schema, $t) = @_;

    # warn "mk_inserter() is deprecated, use _mk_inserter() instead"

    my $last = @{$t->{cols}} - 1;
    # my ($schema, $table, $prefix, @cols) = ($t->{name}, $t->{prefix}, @{$t->{cols}}[1..$last]);

    # my $sql = __PACKAGE__->_mk_ins( "$schema.$t->{name}", @cols );
    my $sql = "INSERT INTO $schema.$t->{name}($t->{sql_ins_cols}) VALUES($t->{qm})";

    my @hr_names = $self->_mk_hr_names( $t->{prefix}, @{$t->{cols}}[1..$last] );

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, map { $hr->{$_} } @hr_names );
    };

    $self->_inject_method("ins_$t->{name}", $method);
}

sub _mk_inserter {
    my ($self, $schema, $t) = @_;

    my $last = @{$t->{cols}} - 1;
    # my ($schema, $table, $prefix, @cols) = ($t->{name}, $t->{prefix}, @{$t->{cols}}[1..$last]);

    # my $sql = __PACKAGE__->_mk_ins( "$schema.$t->{name}", @cols );
    my $sql = "INSERT INTO $schema.$t->{name}($t->{sql_ins_cols}) VALUES($t->{qm})";

    my @hr_names = $self->_mk_hr_names( $t->{prefix}, @{$t->{cols}}[1..$last] );

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, map { $hr->{$_} } @hr_names );
    };

    $self->_inject_method("ins_$t->{name}", $method);
}

sub _mk_updater {
    my ($self, $schema, $t) = @_;

    # warn "mk_updater() is deprecated, use _mk_updater() instead"

    my $sql = "UPDATE $schema.$t->{name} SET $t->{sql_upd_cols} WHERE " . (defined $t->{pk} ? $t->{pk}[0] : 'id' ) . " = ?";
    my @hr_names = $self->_mk_hr_names( $t->{prefix}, @{$t->{cols}} );

    # remove the first field (usually 'id')
    shift @hr_names;

    # add the 'primary key' field
    if ( defined $t->{pk} ) {
        push @hr_names, $t->{pk}[2];
    }
    else {
        push @hr_names, "$t->{prefix}_id";
    }

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, map { $hr->{$_} } @hr_names );
    };

    $self->_inject_method("upd_$t->{name}", $method);
}

sub mk_updater {
    my ($self, $schema, $t) = @_;

    my $sql = "UPDATE $schema.$t->{name} SET $t->{sql_upd_cols} WHERE " . (defined $t->{pk} ? $t->{pk}[0] : 'id' ) . " = ?";
    my @hr_names = $self->_mk_hr_names( $t->{prefix}, @{$t->{cols}} );

    # remove the first field (usually 'id')
    shift @hr_names;

    # add the 'primary key' field
    if ( defined $t->{pk} ) {
        push @hr_names, $t->{pk}[2];
    }
    else {
        push @hr_names, "$t->{prefix}_id";
    }

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, map { $hr->{$_} } @hr_names );
    };

    $self->_inject_method("upd_$t->{name}", $method);
}

sub _mk_deleter {
    my ($self, $schema, $table, $prefix, $id) = @_;

    # my $sql = "DELETE FROM $schema.$table WHERE $id = ?";
    my $sql = __PACKAGE__->_mk_del("$schema.$table", $id);

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, $hr->{"${prefix}_${id}"} );
    };

    $self->_inject_method("del_$table", $method);
}

sub mk_deleter {
    my ($self, $schema, $table, $prefix, $id) = @_;

    # warn "mk_deleter() is deprecated, use _mk_deleter() instead"

    # my $sql = "DELETE FROM $schema.$table WHERE $id = ?";
    my $sql = __PACKAGE__->_mk_del("$schema.$table", $id);

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_do( $sql, $hr->{"${prefix}_${id}"} );
    };

    $self->_inject_method("del_$table", $method);
}

sub _mk_selecter {
    my ($self, $schema, $t) = @_;
    __PACKAGE__->mk_selecter( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}} );
}

sub mk_selecter_from {
    my ($self, $schema, $t) = @_;
    warn "mk_selecter_from() is deprecated, use _mk_selecter() instead";
    __PACKAGE__->mk_selecter( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}} );
}

sub mk_selecter {
    my ($self, $schema, $table, $prefix, $id, @cols) = @_;

    my $cols = __PACKAGE__->_mk_sel_cols( $prefix, $id, @cols );
    my $field = ref $id ? $id->[0] : $id;
    my $sql = "SELECT $cols FROM $schema.$table $prefix WHERE $prefix.$field = ?";

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_row( $sql, $hr->{"${prefix}_${id}"} );
    };

    $self->_inject_method("sel_$table", $method);
}

# need to add a 'mk_selecter_all'

sub mk_select_row {
    my ($self, $method_name, $stm, $hr_names) = @_;

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_row( $stm, map { $hr->{$_} } @$hr_names );
    };

    $self->_inject_method($method_name, $method);
}

sub mk_select_rows {
    my ($self, $method_name, $stm, $hr_names) = @_;

    $hr_names = [] unless ref $hr_names eq 'ARRAY';

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_rows( $stm, map { $hr->{$_} } @$hr_names );
    };

    $self->_inject_method($method_name, $method);
}

# easier way of doing the thing below
sub _mk_selecter_using {
    my ($self, $schema, $table, $col) = @_;
    __PACKAGE__->mk_selecter_using( $schema, $table->{name}, $table->{prefix}, $col, @{$table->{cols}} );
}

sub mk_selecter_using {
    my ($self, $schema, $table, $prefix, $col, @cols) = @_;

    my $cols = __PACKAGE__->_mk_sel_cols( $prefix, @cols );
    my $sql = "SELECT $cols FROM $schema.$table $prefix WHERE $prefix.$col = ?";

    my $class = ref $self || $self;

    # create the closure
    my $method =  sub {
        my ($self, $hr) = @_;
        return $self->_row( $sql, $hr->{"${prefix}_${col}"} );
    };

    $self->_inject_method("sel_${table}_using_${col}", $method);
}

sub _mk_sel_fqt {
    my ($class, $schema, $tablename, $prefix) = @_;
    return "$schema.$tablename $prefix";
}

# has side-effects
sub _mk_sql {
    my ($self, $schema, $table) = @_;
    foreach my $t ( values %$table ) {
        $self->_mk_sql_for( $schema, $t );
    }
}

# has side-effects
sub _mk_sql_for {
    my ($self, $schema, $t) = @_;

    # generate some helpful sql while we're here
    $t->{sql_fqt} = $self->_mk_sel_fqt($schema, $t->{name}, $t->{prefix}); # fully qualified table
    $t->{sql_sel_cols} = $self->_mk_sel_cols( $t->{prefix}, @{$t->{cols}} );
    $t->{sql_ins_cols} = $self->_mk_ins_cols( $t->{prefix}, @{$t->{cols}} );
    $t->{sql_upd_cols} = $self->_mk_upd_cols( $t );

    $t->{qm} = $self->_mk_qm( @{$t->{cols}} );
}

# injects the accessors into the package's namespace
sub _mk_sql_accessors {
    my ($self, $schema, $table) = @_;
    # warn "_mk_sql_accessors() is deprecated, use _mk_accessors() instead"
    foreach my $t ( values %$table ) {
        __PACKAGE__->mk_inserter( $schema, $t );
        __PACKAGE__->mk_updater( $schema, $t );
        __PACKAGE__->mk_deleter( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}}[0] );
    }
}

sub _mk_db_accessors {
    my ($self, $schema, $table) = @_;
    foreach my $t ( values %$table ) {
        __PACKAGE__->_mk_inserter( $schema, $t );
        __PACKAGE__->_mk_updater( $schema, $t );
        __PACKAGE__->_mk_deleter( $schema, $t->{name}, $t->{prefix}, @{$t->{cols}}[0] );
    }
}

sub begin_work {
    my ($self) = @_;
    $self->dbh()->begin_work();
}

sub commit {
    my ($self) = @_;
    $self->dbh()->commit();
}

sub rollback {
    my ($self) = @_;
    $self->dbh()->rollback();
}

## ----------------------------------------------------------------------------
# methods

sub get_sth {
    my ($self, $stm) = @_;
    return $self->{dbh}->prepare_cached( $stm );
}

## ----------------------------------------------------------------------------
# utility methods which are non-SQL things

sub _inject_method {
    my ($self, $method_name, $method) = @_;

    # don't have to check to see if $method_name is 'DESTROY' since it never will be
    my $class = ref $self || $self;

    # inject into package's namespace
    unless ( defined &{"${class}::$method_name"} ) {
        no strict 'refs';
        *{"${class}::$method_name"} = $method;
    }
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
