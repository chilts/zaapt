#!/usr/bin/perl
## ----------------------------------------------------------------------------

use strict;
use warnings;

use Data::Dumper;
use Config::Simple;
use DBI;
use Log::Log4perl qw(get_logger :levels);
use MIME::Lite;
use String::Random qw(random_string);
use Zaapt;

## ----------------------------------------------------------------------------

my $cfg = {};
my $logger;

MAIN: {
    my ($cfg_file) = @ARGV;

    Config::Simple->import_from($cfg_file, $cfg);

    # get the logger
    $logger = get_logger();
    $logger->level( $INFO );

    # pick a layout
    my $layout = Log::Log4perl::Layout::PatternLayout->new( "%d %p %F{1}[%5L] %m%n" );

    # choose and setup the appender
    my $appender = Log::Log4perl::Appender->new(
        "Log::Dispatch::File",
        filename => "$cfg->{log_dir}/send-email.log",
        mode     => "append",
    );
    $appender->layout( $layout );
    $logger->add_appender( $appender );

    $logger->info('-' x 79);
    $logger->info("$0: started");

    # program starts proper
    my $dbh =  DBI->connect(
        "dbi:Pg:dbname=$cfg->{db_name}",
        $cfg->{db_user},
        undef,
        { RaiseError => 1, AutoCommit => 1, PrintError => 1 }
    );

    unless ( defined $dbh ) {
        $logger->fatal("Couldn't connect to database");
        die "Couldn't connect to database";
    }

    $logger->debug("got database handle");

    my $zaapt = Zaapt->new({ store => 'Pg', dbh => $dbh });
    my $email = $zaapt->get_model('Email');

    $logger->debug("got \$zaapt and \$email");

    process_emails( $zaapt, $email, $logger );

    $dbh->disconnect();
    $logger->info("$0: finished");
    $logger->debug(' ');
}

## ----------------------------------------------------------------------------

sub process_emails {
    my ($zaapt, $email) = @_;

    my $done = 0;
    my $i = 0;

    while ( !$done ) {
        $zaapt->start_tx;
        my $recipient = $email->sel_recipient_next_not_sent();

        unless ( defined $recipient ) {
            $done = 1;
            $zaapt->rollback_tx;
            next;
        }

        $logger->info("Recipient: a_id=$recipient->{a_id}, r_id=$recipient->{r_id}, e_id=$recipient->{e_id} - '$recipient->{e_subject}'");

        # see if this account already has an 'info' row
        my $info = $email->sel_info({ a_id => $recipient->{a_id} });

        if ( defined $info ) {
            $logger->info("Got info: sent=$info->{i_sent}, failed=$info->{i_failed}");
        }
        else {
            $logger->info("Info not available");
            # insert a new token
            my $i_token = random_string('0' x 32, [ 'A'..'Z', 'a'..'z', '0'..'9' ]);
            my $ret = $email->ins_info({
                a_id    => $recipient->{a_id},
                i_token => $i_token,
                i_sent  => 0,
                i_failed  => 0,
            });
            $logger->info("Got '$ret' from ins_info()");

            $info = $email->sel_info({ a_id => $recipient->{a_id} });
            die "Couldn't create"
                unless defined $info;
        }

        # create the email message
        my $msg = MIME::Lite->new(
            From    => $cfg->{email_from_address},
            To      => $recipient->{a_email},
            Subject => $recipient->{e_subject},
            Type    => 'multipart/alternative',
        );

        # add the footer here...

        $msg->attach( Type => 'text/plain', Data => $recipient->{e_text} );
        # ToDo: dependant on type_id, this should be converted to HTML
        # $msg->attach( Type => 'text/html', Data => $recipient->{e_html} );

        eval {
            my $sys_str = "/usr/sbin/sendmail -f $recipient->{a_email} -t -oi -oem";
            if ( $msg->send('sendmail', $sys_str) ) {
                $logger->info('...sent OK');
                $email->upd_recipient({
                    r_id => $recipient->{r_id},
                    r_issent => 1
                });
                # set the info
                $info->{i_sent}++;
                $email->upd_info( $info );
            }
            else {
                $logger->warn('Sending the email failed');
                $email->upd_recipient({
                    r_id => $recipient->{r_id},
                    r_issent => 1,
                    r_iserror => 1
                });
                # set the info
                $info->{i_failed}++;
                $email->upd_info( $info );
            }
        };
        if ( $@ ) {
            $logger->info('...error sending email');
            $logger->warn($@);
            $email->upd_recipient({
                r_id => $recipient->{r_id},
                r_issent => 1,
                r_iserror => 1,
                r_error => $@,
            });
            # set the info
            $info->{i_failed}++;
            $email->upd_info( $info );
        }

        $i++;
        $logger->info("...done ($i)");
        # $zaapt->rollback_tx();
        $zaapt->commit_tx();
    }

    $logger->info("$i emails sent");
}

## ----------------------------------------------------------------------------
