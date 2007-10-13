## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Account;
use base qw( Zaapt::Store::Pg Zaapt::Model::Account );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $schema = 'account';

my $tables = {
    account => {
        schema => $schema,
        name   => 'account',
        prefix => 'a',
        cols   => [ qw(id username firstname lastname email notify salt password confirmed admin logins last ts:inserted ts:updated) ],
    },
    role => {
        schema => $schema,
        name   => 'role',
        prefix => 'r',
        cols   => [ qw(id name description ts:inserted ts:updated) ],
    },
    privilege => {
        schema => $schema,
        name   => 'privilege',
        prefix => 'p',
        cols   => [
            'id',
            [ 'account_id', 'fk', 'a_id' ],
            [ 'role_id', 'fk', 'r_id' ],
            qw(ts:inserted ts:updated)
        ],
    },
    confirm => {
        schema => $schema,
        name   => 'confirm',
        prefix => 'c',
        cols   => [
            qw(account_id code ts:inserted ts:updated)
        ],
    },
};

my $join = {
    a_p  => "JOIN $schema.privilege p ON (a.id = p.account_id)",
    p_r  => "JOIN account.role r ON (p.role_id = r.id)",
};

sub _get_tables { return $tables; }

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_sql_accessors( $schema, $tables );

## ----------------------------------------------------------------------------

# account
__PACKAGE__->_mk_selecter( $schema, $tables->{account} );
__PACKAGE__->mk_select_rows( 'sel_account_all', "SELECT $tables->{account}{sql_sel_cols} FROM $tables->{account}{sql_fqt} ORDER BY a.id" );

# role
__PACKAGE__->_mk_selecter( $schema, $tables->{role} );
__PACKAGE__->mk_select_rows( 'sel_role_all', "SELECT $tables->{role}{sql_sel_cols} FROM $tables->{role}{sql_fqt} ORDER BY a.id" );

# privilege
my $main_cols = "$tables->{account}{sql_sel_cols}, $tables->{privilege}{sql_sel_cols}, $tables->{role}{sql_sel_cols}";
my $main_joins = "$tables->{account}{sql_fqt} $join->{a_p} $join->{p_r}";
__PACKAGE__->_mk_selecter( $schema, $tables->{privilege} );
__PACKAGE__->mk_select_rows( 'sel_privilege_all', "SELECT $main_cols FROM $main_joins ORDER BY a.id, r.id", [] );
__PACKAGE__->mk_select_rows( 'sel_privilege_all_order_by_account', "SELECT $main_cols FROM $main_joins ORDER BY a.id, r.id", [ ] );
__PACKAGE__->mk_select_rows( 'sel_privilege_all_order_by_role', "SELECT $main_cols FROM $main_joins ORDER BY r.id, a.id", [ ] );

# confirm
__PACKAGE__->_mk_selecter( $schema, $tables->{confirm} );

## ----------------------------------------------------------------------------
# methods

my $ins_account = "INSERT INTO account.account(username, firstname, lastname, email, notify, salt, password, admin, confirmed) VALUES(?, ?, ?, ?, ?, ?, md5(? || ?), COALESCE(?, False), COALESCE(?, False))";
sub ins_account {
    my ($self, $hr) = @_;
    $self->_do( $ins_account, $hr->{a_username}, $hr->{a_firstname}, $hr->{a_lastname}, $hr->{a_email}, $hr->{a_notify}, $hr->{a_salt}, $hr->{a_salt}, $hr->{a_password}, $hr->{a_admin}, $hr->{a_confirmed} );
}

my $sel_roles_for_account = "SELECT a.username AS a_username, r.id AS r_id, r.name AS r_name FROM account.account a JOIN account.privilege p ON (a.id = p.account_id) JOIN account.role r ON (p.role_id = r.id) WHERE a.id = ?";
sub sel_roles_for_account {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_roles_for_account, $hr->{a_id} );
}

my $sel_account_using_username = "SELECT $tables->{account}{sql_sel_cols} FROM $tables->{account}{sql_fqt} WHERE a.username = ?";
sub sel_account_using_username {
    my ($self, $hr) = @_;
    return $self->_row( $sel_account_using_username, $hr->{a_username} );
}

my $sel_account_for_authentication = "SELECT $tables->{account}{sql_sel_cols} FROM $tables->{account}{sql_fqt} WHERE a.username = ? AND a.password = md5(salt || ?)";
sub sel_account_for_authentication {
    my ($self, $hr) = @_;
    return $self->_row( $sel_account_for_authentication, $hr->{a_username}, $hr->{a_password} );
}

my $sel_account_check_password = "SELECT $tables->{account}{sql_sel_cols} FROM $tables->{account}{sql_fqt} WHERE a.id = ? AND a.password = md5(salt || ?)";
sub sel_account_check_password {
    my ($self, $hr) = @_;
    return $self->_row( $sel_account_check_password, $hr->{a_id}, $hr->{a_password} );
}

my $upd_account_admin_toggle = "UPDATE account.account SET admin = not admin WHERE id = ?";
sub upd_account_admin_toggle {
    my ($self, $hr) = @_;
    return $self->_do( $upd_account_admin_toggle, $hr->{a_id} );
}

my $upd_account = __PACKAGE__->_mk_upd( 'account.account', 'id', qw(username firstname lastname email notify confirmed admin));
sub upd_account {
    my ($self, $hr) = @_;
    $self->_do( $upd_account, $hr->{a_username}, $hr->{a_firstname}, $hr->{a_lastname}, $hr->{a_email}, $hr->{a_notify}, $hr->{a_confirmed}, $hr->{a_admin}, $hr->{a_id} );
}

my $upd_password = "UPDATE account.account SET password = md5(salt || ?) WHERE id = ?";
sub upd_password {
    my ($self, $hr) = @_;
    $self->_do( $upd_password, $hr->{a_password}, $hr->{a_id} );
}

my $upd_logins = "UPDATE account.account SET logins = logins + 1 WHERE id = ?";
sub upd_logins {
    my ($self, $hr) = @_;
    $self->_do( $upd_logins, $hr->{a_id} );
}

my $upd_last = "UPDATE account.account SET last = CURRENT_TIMESTAMP WHERE id = ?";
sub upd_last {
    my ($self, $hr) = @_;
    $self->_do( $upd_last, $hr->{a_id} );
}

my $ins_confirm = __PACKAGE__->_mk_ins( 'account.confirm', qw(account_id code) );
sub ins_confirm {
    my ($self, $hr) = @_;
    $self->_do( $ins_confirm, $hr->{a_id}, $hr->{c_code} );
}

my $del_confirm = __PACKAGE__->_mk_del( 'account.confirm', qw(account_id) );
sub del_confirm {
    my ($self, $hr) = @_;
    $self->_do( $del_confirm, $hr->{a_id} );
}

# takes a account.name and confirm.code
sub confirm {
    my ($self, $hr) = @_;

    $self->dbh()->begin_work();
    my $account = $self->sel_account_using_username($hr);
    unless ( defined $account ) {
        $self->dbh()->rollback();
        return;
    }
    my $code = $self->sel_confirm( $account );
    unless ( defined $code ) {
        $self->dbh()->rollback();
        return;
    }

    # if we are here, then they have a confirmation code, let's check it
    unless ( $hr->{c_code} eq $code->{c_code} ) {
        $self->dbh()->rollback();
        return;
    }

    $account->{a_confirmed} = 1;
    $self->upd_account( $account );
    $self->del_confirm( $account );
    $self->dbh()->commit();
    return 1;
}

sub _nuke {
    my ($self) = @_;
    $self->dbh()->begin_work();
    $self->dbh()->do( "DELETE FROM account.privilege" );
    $self->dbh()->do( "DELETE FROM account.role" );
    $self->dbh()->do( "DELETE FROM account.account" );
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
