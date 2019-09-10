use base "installedtest";
use strict;
use testapi;
use utils;
use cockpit;

sub run {
    my $self = shift;
    # check cockpit appears to be enabled and running and firewall is setup
    assert_script_run 'systemctl is-enabled cockpit.socket';
    assert_script_run 'systemctl is-active cockpit.socket';
    assert_script_run 'firewall-cmd --query-service cockpit';
    # test cockpit web UI start
    start_cockpit(0);
    # quit firefox (return to console)
    quit_firefox;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
