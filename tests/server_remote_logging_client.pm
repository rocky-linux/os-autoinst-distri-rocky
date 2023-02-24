use base "installedtest";
use strict;
use testapi;
use lockapi;

sub run {
    my $self = shift;
    if (not(check_screen "root_console", 0)) {
        $self->root_console(tty => 3);
    }
    # ensure rsyslog is installed and enabled
    script_run "dnf -y install rsyslog", 180;
    script_run "systemctl enable --now rsyslog.service";
    # set up forwarding
    assert_script_run "printf 'action(type=\"omfwd\"\nTarget=\"172.16.2.112\" Port=\"514\" Protocol=\"udp\")' >> /etc/rsyslog.conf";
    # for debugging
    upload_logs "/etc/rsyslog.conf";
    # wait for server to be ready, then restart rsyslog
    mutex_lock "rsyslog_server_ready";
    mutex_unlock "rsyslog_server_ready";
    assert_script_run "systemctl restart rsyslog.service";
    # send a test message and tell server we did it
    assert_script_run "logger user.warn XXX RSYSLOG TEST MESSAGE";
    sleep 2;
    # for debugging
    upload_logs "/var/log/messages";
    mutex_create "rsyslog_message_sent";
    # wait for server to tell us it got the message
    mutex_lock "rsyslog_message_received";
    mutex_unlock "rsyslog_message_received";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
