## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Account;
use base qw( Zaapt::Store::Pg Zaapt::Model::Account );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $table = {
    account => {
        schema => 'account',
        name   => 'account',
        prefix => 'a',
        cols   => [ qw(id username) ],
    },
};

# table names
my $account_tablename = "account.account a";
my $role_tablename = "account.role r";
my $privilege_tablename = "account.privilege p";
my $confirm_tablename = "account.confirm c";

# helper
my $account_cols = __PACKAGE__->_mk_cols( 'a', qw(id username firstname lastname email notify salt password confirmed admin logins last ts:inserted ts:updated) );
my $role_cols = __PACKAGE__->_mk_cols( 'r', qw(id name description) );
my $privilege_cols = __PACKAGE__->_mk_cols( 'p', qw(id account_id role_id) );
my $confirm_cols = __PACKAGE__->_mk_cols( 'c', qw(account_id code) );

# account
my $ins_account = "INSERT INTO account.account(username, firstname, lastname, email, notify, salt, password, admin, confirmed) VALUES(?, ?, ?, ?, ?, ?, md5(? || ?), COALESCE(?, False), COALESCE(?, False))";
my $del_account = __PACKAGE__->_mk_del( 'account.account', qw(id) );
my $sel_account = "SELECT $account_cols FROM $account_tablename WHERE id = ?";
my $sel_account_using_username = "SELECT $account_cols FROM $account_tablename WHERE username = ?";
my $upd_account = __PACKAGE__->_mk_upd( 'account.account', 'id', qw(username firstname lastname email notify confirmed admin));
my $upd_password = "UPDATE account.account SET password = md5(salt || ?) WHERE id = ?";
my $upd_logins = "UPDATE account.account SET logins = logins + 1 WHERE id = ?";
my $upd_last = "UPDATE account.account SET last = CURRENT_TIMESTAMP WHERE id = ?";
my $sel_account_all = "SELECT $account_cols FROM $account_tablename ORDER BY a.id";

# role
my $ins_role = __PACKAGE__->_mk_ins( 'account.role', qw(name description) );
my $upd_role = __PACKAGE__->_mk_upd( 'account.role', 'id', qw(name description) );
my $del_role = __PACKAGE__->_mk_del( 'account.role', qw(id) );
my $sel_role = __PACKAGE__->_mk_sel( 'account.role', 'r', qw(name description) );
my $sel_all_roles = "SELECT $role_cols FROM $role_tablename ORDER BY name"; # deprecated
my $sel_role_all = "SELECT $role_cols FROM $role_tablename ORDER BY name";

# privilege
my $ins_privilege = __PACKAGE__->_mk_ins( 'account.privilege', qw(account_id role_id) );
my $del_privilege = __PACKAGE__->_mk_del( 'account.privilege', qw(id) );
my $sel_privilege = "SELECT $privilege_cols FROM $privilege_tablename WHERE p.id = ?";
my $sel_privilege_all = "SELECT $account_cols, $privilege_cols, $role_cols FROM $account_tablename JOIN $privilege_tablename ON (a.id = p.account_id) JOIN $role_tablename ON (p.role_id = r.id) ORDER BY a.id, r.id";
my $sel_privilege_all_by_account = "SELECT $account_cols, $privilege_cols, $role_cols FROM $account_tablename JOIN $privilege_tablename ON (a.id = p.account_id) JOIN $role_tablename ON (p.role_id = r.id) ORDER BY a.id, r.id";
my $sel_privilege_all_by_role = "SELECT $role_cols, $privilege_cols, $account_cols FROM $role_tablename JOIN $privilege_tablename ON (r.id = p.role_id) JOIN $account_tablename ON (p.account_id = a.id) ORDER BY r.id, a.id";

# confirm
my $ins_confirm = __PACKAGE__->_mk_ins( 'account.confirm', qw(account_id code) );
my $sel_confirm = "SELECT $confirm_cols FROM $confirm_tablename WHERE account_id = ?";
my $del_confirm = __PACKAGE__->_mk_del( 'account.confirm', qw(account_id) );;

# general select queries
my $sel_account_for_authentication = "SELECT $account_cols FROM $account_tablename WHERE username = ? AND password = md5(salt || ?)";
my $sel_roles_for_account = "SELECT a.username AS a_username, r.id AS r_id, r.name AS r_name FROM account.account a JOIN account.privilege p ON (a.id = p.account_id) JOIN account.role r ON (p.role_id = r.id) WHERE a.id = ?";

## ----------------------------------------------------------------------------
# methods

sub get_table_details {
    my ($class, $tablename) = @_;
    return unless exists $table->{$tablename};
    return $table->{$tablename};
}

sub ins_account {
    my ($self, $hr) = @_;
    $self->_do( $ins_account, $hr->{a_username}, $hr->{a_firstname}, $hr->{a_lastname}, $hr->{a_email}, $hr->{a_notify}, $hr->{a_salt}, $hr->{a_salt}, $hr->{a_password}, $hr->{a_admin}, $hr->{a_confirmed} );
}

sub ins_privilege {
    my ($self, $hr) = @_;
    $self->_do( $ins_privilege, $hr->{a_id}, $hr->{r_id} );
}

sub ins_role {
    my ($self, $hr) = @_;
    $self->_do( $ins_role, $hr->{r_name}, $hr->{r_description} );
}

sub upd_role {
    my ($self, $hr) = @_;
    $self->_do( $upd_role, $hr->{r_name}, $hr->{r_description}, $hr->{r_id} );
}

sub del_role {
    my ($self, $hr) = @_;
    $self->_do( $del_role, $hr->{r_id} );
}

sub sel_role {
    my ($self, $hr) = @_;
    return $self->_row( $sel_role, $hr->{r_id} );
}

sub sel_all_roles { # deprecated
    my ($self, $hr) = @_;
    warn "Account::sel_all_roles(): is deprecated";
    return $self->_rows( $sel_all_roles );
}

sub sel_role_all {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_role_all );
}

sub sel_roles_for_account {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_roles_for_account, $hr->{a_id} );
}

sub del_privilege {
    my ($self, $hr) = @_;
    $self->_do( $del_privilege, $hr->{p_id} );
}

sub sel_privilege {
    my ($self, $hr) = @_;
    return $self->_row( $sel_privilege, $hr->{p_id} );
}

sub sel_privilege_all {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_privilege_all );
}

sub sel_privilege_all_by_account {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_privilege_all_by_account );
}

sub sel_privilege_all_by_role {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_privilege_all_by_role );
}

sub sel_account {
    my ($self, $hr) = @_;
    return $self->_row( $sel_account, $hr->{a_id} );
}

sub del_account {
    my ($self, $hr) = @_;
    $self->_do( $del_account, $hr->{a_id} );
}

sub sel_account_using_username {
    my ($self, $hr) = @_;
    return $self->_row( $sel_account_using_username, $hr->{a_username} );
}

sub sel_account_for_authentication {
    my ($self, $hr) = @_;
    return $self->_row( $sel_account_for_authentication, $hr->{a_username}, $hr->{a_password} );
}

sub upd_account {
    my ($self, $hr) = @_;
    $self->_do( $upd_account, $hr->{a_username}, $hr->{a_firstname}, $hr->{a_lastname}, $hr->{a_email}, $hr->{a_notify}, $hr->{a_confirmed}, $hr->{a_admin}, $hr->{a_id} );
}

sub upd_password {
    my ($self, $hr) = @_;
    $self->_do( $upd_password, $hr->{a_password}, $hr->{a_id} );
}

sub upd_logins {
    my ($self, $hr) = @_;
    $self->_do( $upd_logins, $hr->{a_id} );
}

sub upd_last {
    my ($self, $hr) = @_;
    $self->_do( $upd_last, $hr->{a_id} );
}

sub sel_account_all {
    my ($self) = @_;
    return $self->_rows( $sel_account_all );
}

sub ins_confirm {
    my ($self, $hr) = @_;
    $self->_do( $ins_confirm, $hr->{a_id}, $hr->{c_code} );
}

sub sel_confirm {
    my ($self, $hr) = @_;
    $self->_row( $sel_confirm, $hr->{a_id} );
}

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
