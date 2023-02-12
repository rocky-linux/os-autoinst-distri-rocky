package bugzilla;

use strict;

use base 'Exporter';
use Exporter;
use lockapi;
use testapi;
use utils;
use POSIX qw(strftime);
use JSON;
use REST::Client;

our @EXPORT = qw(convert_to_bz_timestamp get_newest_bug check_bug_status_field close_notabug);

sub start_bugzilla_client {
    # Start a Bugzilla REST client for setting up communication.
    # This is a local subroutine, not intended for export.
    my $bugzilla = REST::Client->new();
    $bugzilla->setHost("https://bugzilla.redhat.com");
    return $bugzilla;
}

sub convert_to_bz_timestamp {
    # This subroutine takes the epoch time and converts it to
    # the Bugzilla timestamp format (YYYY-MM-DDTHH:MM:SS)
    # in the GMT time zone.
    my $epochtime = shift;
    my $bz_stamp = strftime("%FT%T", gmtime($epochtime));
    return $bz_stamp;
}

sub get_newest_bug {
    # This subroutine makes an API call to Bugzilla and
    # fetches the newest bug that have been created.
    # This will be the bug created by Anaconda in this
    # test run.
    my ($timestamp, $login) = @_;
    $timestamp = convert_to_bz_timestamp($timestamp);
    my $bugzilla = start_bugzilla_client();
    my $api_call = $bugzilla->GET("/rest/bug?creator=$login&status=NEW&created_after=$timestamp");
    my $rest_json = decode_json($api_call->responseContent());
    my $last_id;
    eval {
        $last_id = $rest_json->{bugs}[-1]->{id};
        1;
    } or do {
        record_soft_failure "Bugzilla returned an empty list of bugs which is unexpected!";
        $last_id = 0;
    };
    return $last_id;
}

sub check_bug_status_field {
    # This will check that the status field matches the one
    # tested status. Arguments are bug_id and status.
    my ($bug_id, $status) = @_;
    my $bugzilla = start_bugzilla_client();
    my $api_call = $bugzilla->GET("/rest/bug/$bug_id");
    my $rest_json = decode_json($api_call->responseContent());
    if ($rest_json->{bugs}[0]->{status} eq $status) {
        return 1;
    }
    else {
        return 0;
    }
}

sub close_notabug {
    # This will call Bugzilla and close the bug with the requested
    # bug id as a NOTABUG.
    my ($bug_id, $key) = @_;
    my $bugzilla = start_bugzilla_client();
    my $api_call = $bugzilla->PUT("/rest/bug/$bug_id?api_key=$key&status=CLOSED&resolution=NOTABUG");
    my $rest_json = decode_json($api_call->responseContent());
    if ($rest_json->{bugs}[0]->{changes}->{status}->{added} ne "CLOSED") {
        return 0;
    }
    else {
        return 1;
    }
}
