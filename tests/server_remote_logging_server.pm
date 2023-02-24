use base "installedtest";
use strict;
use testapi;
use lockapi;
use mmapi;

sub run {
    my $self = shift;
    if (not(check_screen "root_console", 0)) {
        $self->root_console(tty => 3);
    }
    # ensure rsyslog is installed and enabled
    script_run "dnf -y install rsyslog", 180;
    script_run "systemctl enable --now rsyslog.service";
    # set up imudp module
    assert_script_run 'sed -i -e "s,#module(load=\"imudp\"),module(load=\"imudp\"),g" /etc/rsyslog.conf';
    assert_script_run 'sed -i -e "s,#input(type=\"imudp\",input(type=\"imudp\",g" /etc/rsyslog.conf';
    # open firewall port
    assert_script_run 'firewall-cmd --permanent --add-port=514/udp';
    assert_script_run 'firewall-cmd --reload';
    # start rsyslog
    assert_script_run "systemctl restart rsyslog.service";
    # tell client we're ready and wait for it to send the message
    mutex_create("rsyslog_server_ready");
    my $children = get_children();
    my $child_id = (keys %$children)[0];
    mutex_lock('rsyslog_message_sent', $child_id);
    mutex_unlock('rsyslog_message_sent');
    # check we got the message
    assert_script_run 'grep "XXX RSYSLOG TEST MESSAGE" /var/log/messages';
    # tell child test we were successful
    mutex_create("rsyslog_message_received");
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
