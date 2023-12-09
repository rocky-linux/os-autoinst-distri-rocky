use base "installedtest";
use strict;
use testapi;
use utils;
use cockpit;

sub run {
    my $self = shift;
    assert_script_run 'dnf -y groupinstall "Headless Management"', 300;
    assert_script_run 'systemctl enable --now cockpit.socket';
    # check cockpit appears to be enabled and running and firewall is setup
    assert_script_run 'systemctl is-enabled cockpit.socket';
    assert_script_run 'systemctl is-active cockpit.socket';
    assert_script_run 'firewall-cmd --query-service cockpit';
    # test cockpit web UI start
    start_cockpit(login => 0);
    # quit firefox (return to console)
    quit_firefox;
    # we don't get back to a prompt instantly and keystrokes while X
    # is still shutting down are swallowed, so be careful before
    # finishing (and handing off to next test)
    assert_screen "root_console";
    wait_still_screen 5;
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
