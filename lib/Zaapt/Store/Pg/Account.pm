## -------------------------------------------------------------------*-perl-*-
package Zaapt::Store::Pg::Account;
use base qw( Zaapt::Store::Pg Zaapt::Model::Account );

use strict;
use warnings;

## ----------------------------------------------------------------------------
# constants

my $schema = 'account';

my $tables = {
    # account tables
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
    permission => {
        schema => $schema,
        name   => 'permission',
        prefix => 'p',
        cols   => [ qw(id name description ts:inserted ts:updated) ],
    },
    ra => {
        schema => $schema,
        name   => 'ra',
        prefix => 'ra',
        cols   => [
            'id',
            [ 'account_id', 'fk', 'a_id' ],
            [ 'role_id', 'fk', 'r_id' ],
            qw(ts:inserted ts:updated) ],
    },
    pa => {
        schema => $schema,
        name   => 'pa',
        prefix => 'pa',
        cols   => [
            'id',
            [ 'role_id', 'fk', 'r_id' ],
            [ 'permission_id', 'fk', 'p_id' ],
            qw(ts:inserted ts:updated) ],
    },
    confirm => {
        schema => $schema,
        name   => 'confirm',
        prefix => 'c',
        cols   => [
            qw(account_id code ts:inserted ts:updated)
        ],
    },
    invitation => {
        schema => $schema,
        name   => 'invitation',
        prefix => 'i',
        cols   => [
            'id',
            [ 'account_id', 'fk', 'a_id' ],
            qw(name email ts:inserted ts:updated)
        ],
    },
    token => {
        schema => $schema,
        name   => 'token',
        prefix => 't',
        cols   => [
            'id',
            [ 'account_id', 'fk', 'a_id' ],
            qw(code ts:inserted ts:updated)
        ],
    },
    # email tables
    email => {
        schema => $schema,
        name   => 'email',
        prefix => 'e',
        cols   => [
            'id',
            qw(subject text html),
            [ 'type_id', 'fk', 't_id' ],
            qw(isbulk ts:inserted ts:updated),
        ],
    },
    # type  => Zaapt::Store::Pg::Common->_get_table( 'type' ),
    recipient => {
        schema => $schema,
        name   => 'recipient',
        prefix => 're',
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
        prefix => 'inf',
        cols => [
            [ 'account_id', 'fk', 'a_id' ],
            qw(token sent failed ts:inserted ts:updated)
        ],
        pk => [ 'account_id', 'fk', 'a_id' ],
    },
};

my $join = {
    # account joins
    a_ra => "JOIN $schema.ra ra ON (a.id = ra.account_id)",
    ra_r => "JOIN $schema.role r ON (ra.role_id = r.id)",
    r_pa => "JOIN $schema.pa pa ON (r.id = pa.role_id)",
    pa_p => "JOIN $schema.permission p ON (pa.permission_id = p.id)",
    a_c  => "JOIN $schema.confirm c ON (a.id = c.account_id)",
    # email joins
    re_e => "JOIN $schema.email e ON (re.email_id = e.id)",
    re_a => "JOIN $schema.account a ON (re.account_id = a.id)",
    a_in => "LEFT JOIN $schema.info inf ON (a.id = inf.account_id)",
};

sub _get_tables { return $tables; }

## ----------------------------------------------------------------------------

# creates {sql_fqt} and {sql_sel_cols}
__PACKAGE__->_mk_sql( $schema, $tables );

# generate the SQL ins/upd/del (no sel)
__PACKAGE__->_mk_store_accessors( $schema, $tables );

## ----------------------------------------------------------------------------

# link all the tables
my $main_cols = "$tables->{account}{sql_sel_cols}, $tables->{role}{sql_sel_cols}, $tables->{permission}{sql_sel_cols}";
my $main_joins = "$tables->{account}{sql_fqt} $join->{a_ra} $join->{ra_r} $join->{r_pa} $join->{pa_p}";
# email cols
my $recipient_cols = "$tables->{recipient}{sql_sel_cols}, $tables->{email}{sql_sel_cols}, $tables->{account}{sql_sel_cols}";
my $recipient_joins = "$tables->{recipient}{sql_fqt} $join->{re_e} $join->{re_a}";
my $info_cols = "$tables->{account}{sql_sel_cols}, $tables->{info}{sql_sel_cols}";
my $info_joins = "$tables->{account}{sql_fqt} $join->{a_in}";

# account
__PACKAGE__->mk_selecter_from( $schema, $tables->{account} );
__PACKAGE__->mk_select_rows( 'sel_account_all', "SELECT $tables->{account}{sql_sel_cols} FROM $tables->{account}{sql_fqt} ORDER BY a.id" );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{account}, 'username' );
__PACKAGE__->mk_select_rows( 'sel_account_all_with_notify', "SELECT $tables->{account}{sql_sel_cols} FROM $tables->{account}{sql_fqt} WHERE notify = True ORDER BY a.id" );

# role
__PACKAGE__->mk_selecter_from( $schema, $tables->{role} );
__PACKAGE__->mk_select_rows( 'sel_role_all', "SELECT $tables->{role}{sql_sel_cols} FROM $tables->{role}{sql_fqt} ORDER BY r.name" );
__PACKAGE__->mk_select_rows( 'sel_role_all_for_account', "SELECT $tables->{account}{sql_sel_cols}, $tables->{role}{sql_sel_cols}  FROM $tables->{account}{sql_fqt} $join->{a_ra} $join->{ra_r} WHERE a.id = ? ORDER BY r.id", [ 'a_id' ] );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{role}, 'name' );

# permission
__PACKAGE__->mk_selecter_from( $schema, $tables->{permission} );
__PACKAGE__->mk_select_rows( 'sel_permission_all', "SELECT $tables->{permission}{sql_sel_cols} FROM $tables->{permission}{sql_fqt} ORDER BY p.id", [] );
__PACKAGE__->mk_select_rows( 'sel_permission_all_for_role', "SELECT $tables->{role}{sql_sel_cols}, $tables->{permission}{sql_sel_cols} FROM $tables->{role}{sql_fqt} $join->{r_pa} $join->{pa_p} WHERE r.id = ? ORDER BY p.id", [ 'r_id' ] );
__PACKAGE__->mk_select_rows( 'sel_permission_all_for_account', "SELECT $main_cols FROM $main_joins WHERE a.id = ? ORDER BY p.id", [ 'a_id' ] );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{permission}, 'name' );

# confirm
__PACKAGE__->mk_selecter_from( $schema, $tables->{confirm} );
__PACKAGE__->mk_select_row( 'sel_confirm_using_account_id', "SELECT $tables->{confirm}{sql_sel_cols} FROM $tables->{confirm}{sql_fqt} WHERE account_id = ?", [ 'a_id' ] );

# ra
__PACKAGE__->_mk_do( 'del_ra_for', "DELETE FROM account.ra WHERE account_id = ?", [ 'a_id' ] );

# pa
__PACKAGE__->_mk_do( 'del_pa_for', "DELETE FROM account.pa WHERE role_id = ?", [ 'r_id' ] );

# invitation
__PACKAGE__->mk_select_rows( 'sel_invitation_all', "SELECT $tables->{invitation}{sql_sel_cols} FROM $tables->{invitation}{sql_fqt} ORDER BY i.id" );
__PACKAGE__->mk_selecter_using_from( $schema, $tables->{invitation}, 'email' );

# token
__PACKAGE__->_mk_do( 'del_token_invalid_for', "DELETE FROM account.token WHERE account_id = ? AND inserted < current_timestamp - '1 hour'::INTERVAL", [ 'a_id' ]);
__PACKAGE__->mk_select_row( 'sel_token_using_account_id', "SELECT $tables->{token}{sql_sel_cols} FROM $tables->{token}{sql_fqt} WHERE account_id = ?", [ 'a_id' ]);
__PACKAGE__->mk_select_row( 'sel_token_valid', "SELECT $tables->{token}{sql_sel_cols} FROM $tables->{token}{sql_fqt} WHERE t.code = ? AND t.inserted > current_timestamp - '1 hour'::INTERVAL", [ 't_code' ]);

# email
__PACKAGE__->mk_selecter( $schema, $tables->{email}{name}, $tables->{email}{prefix}, @{$tables->{email}{cols}} );
__PACKAGE__->mk_select_rows( 'sel_email_all', "SELECT $tables->{email}{sql_sel_cols} FROM $tables->{email}{sql_fqt} ORDER BY e.inserted", [] );
__PACKAGE__->mk_select_rows( 'sel_email_all_bulk', "SELECT $tables->{email}{sql_sel_cols} FROM $tables->{email}{sql_fqt} WHERE isbulk IS True ORDER BY e.inserted", [] );

# recipient
__PACKAGE__->mk_select_row( 'sel_recipient_next_not_sent', "SELECT $recipient_cols FROM $recipient_joins WHERE issent IS False ORDER BY re.id LIMIT 1", [] );

# info
__PACKAGE__->mk_selecter( $schema, $tables->{info}{name}, $tables->{info}{prefix}, @{$tables->{info}{cols}} );
__PACKAGE__->mk_select_row( 'sel_info_using_token', "SELECT $info_cols FROM $info_joins WHERE inf.token = ?", [ 'inf_token' ]);

## ----------------------------------------------------------------------------
# methods

my $ins_account = "INSERT INTO account.account(username, firstname, lastname, email, notify, salt, password, admin, confirmed) VALUES(?, ?, ?, ?, ?, ?, md5(? || ?), COALESCE(?, False), COALESCE(?, False))";
sub ins_account {
    my ($self, $hr) = @_;
    $self->_do( $ins_account, $hr->{a_username}, $hr->{a_firstname}, $hr->{a_lastname}, $hr->{a_email}, $hr->{a_notify}, $hr->{a_salt}, $hr->{a_salt}, $hr->{a_password}, $hr->{a_admin}, $hr->{a_confirmed} );
}

my $sel_roles_for_account = "SELECT a.username AS a_username, r.id AS r_id, r.name AS r_name FROM account.account a JOIN account.permission p ON (a.id = p.account_id) JOIN account.role r ON (p.role_id = r.id) WHERE a.id = ?";
sub sel_roles_for_account {
    my ($self, $hr) = @_;
    return $self->_rows( $sel_roles_for_account, $hr->{a_id} );
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
    my $code = $self->sel_confirm_using_account_id( $account );
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
    $self->_do( "DELETE FROM $schema.info" );
    $self->_do( "DELETE FROM $schema.email" );
    $self->_do( "DELETE FROM $schema.pa" );
    $self->_do( "DELETE FROM $schema.permission" );
    $self->_do( "DELETE FROM $schema.ra" );
    $self->_do( "DELETE FROM $schema.role" );
    $self->_do( "DELETE FROM $schema.account" );
    $self->dbh()->commit();
}

## ----------------------------------------------------------------------------
1;
## ----------------------------------------------------------------------------
