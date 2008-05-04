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
    die "Please provide a config file"
        unless defined $cfg_file;

    Config::Simple->import_from($cfg_file, $cfg);

    # get the logger
    $logger = get_logger();
    $logger->level( $INFO );

    # pick a layout
    my $layout = Log::Log4perl::Layout::PatternLayout->new( "%d %p %F{1}[%5L] %m%n" );

    # choose and setup the appender
    my $appender = Log::Log4perl::Appender->new(
        "Log::Dispatch::File",
        filename => "$cfg->{log_dir}/zaapt-send-email.log",
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
    my $email = $zaapt->get_model('Account');

    $logger->debug("got \$zaapt and \$email");

    process_emails( $zaapt, $email, $logger );

    $dbh->disconnect();
    $logger->info("$0: finished");
    $logger->info(' ');
}

## ----------------------------------------------------------------------------

sub process_emails {
    my ($zaapt, $email) = @_;

    my $done = 0;
    my $i = 0;

    #while ( !$done ) {
    while ( !$i ) {
        $zaapt->start_tx;
        my $recipient = $email->sel_recipient_next_not_sent();

        unless ( defined $recipient ) {
            $done = 1;
            $zaapt->rollback_tx;
            next;
        }

        $logger->info("Recipient: a_id=$recipient->{a_id}, re_id=$recipient->{re_id}, e_id=$recipient->{e_id} - '$recipient->{e_subject}'");

        # see if this account already has an 'info' row
        my $info = $email->sel_info({ a_id => $recipient->{a_id} });

        $logger->info("here");

        if ( defined $info ) {
            $logger->info("Got info: sent=$info->{inf_sent}, failed=$info->{inf_failed}");
        }
        else {
            $logger->info("Info not available");
            # insert a new token
            my $inf_token = random_string('0' x 32, [ 'A'..'Z', 'a'..'z', '0'..'9' ]);
            my $ret = $email->ins_info({
                a_id    => $recipient->{a_id},
                inf_token => $inf_token,
                inf_sent  => 0,
                inf_failed  => 0,
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

        # to add the footer, get the account:location setting first
        my $zaapt_model = $zaapt->get_model('Zaapt');
        my $model = $zaapt_model->sel_model_using_name({ m_name => 'account' });
        my $location_setting = $zaapt_model->sel_setting_in_model({
            m_id   => $model->{m_id},
            s_name => 'location',
        });
        my $unsubscribe_url = "http://$cfg->{domain_name}/$location_setting->{s_value}/unsubscribe.html";

        $recipient->{e_text} .= <<"EOF";
If you do not wish to receive notifications, please click here:

$unsubscribe_url?_act=unsubscribe&inf_token=$info->{inf_token}
EOF

        $recipient->{e_html} .= <<"EOF";
<p>
    If you do not wish to receive notifications, please <a href="$unsubscribe_url?_act=unsubscribe&amp;inf_token=$info->{inf_token}">unsubscribe</a>
</p>
EOF

        $msg->attach( Type => 'text/plain', Data => $recipient->{e_text} );
        # ToDo: dependant on type_id, this should be converted to HTML, for now
        # though assume just plain HTML
        $msg->attach( Type => 'text/html', Data => $recipient->{e_html} );

        eval {
            my $sys_str = "/usr/sbin/sendmail -f $recipient->{a_email} -t -oi -oem";
            if ( $msg->send('sendmail', $sys_str) ) {
                $logger->info('...sent OK');
                $email->upd_recipient({
                    re_id => $recipient->{re_id},
                    re_issent => 1
                });
                # set the info
                $info->{inf_sent}++;
                $email->upd_info( $info );
            }
            else {
                $logger->warn('Sending the email failed');
                $email->upd_recipient({
                    re_id => $recipient->{re_id},
                    re_issent => 1,
                    re_iserror => 1
                });
                # set the info
                $info->{inf_failed}++;
                $email->upd_info( $info );
            }
        };
        if ( $@ ) {
            $logger->info('...error sending email');
            $logger->warn($@);
            $email->upd_recipient({
                re_id => $recipient->{re_id},
                re_issent => 1,
                re_iserror => 1,
                re_error => $@,
            });
            # set the info
            $info->{inf_failed}++;
            $email->upd_info( $info );
        }

        $i++;
        $logger->info("...done ($i)");
        $zaapt->commit_tx();
    }

    $logger->info("$i emails sent");
}

## ----------------------------------------------------------------------------
