use base "installedtest";
use strict;
use testapi;
use utils;
use cockpit;

sub run {
    my $self = shift;

    # Rocky 10+ specific changes
    if (get_var("DISTRI") eq "rocky" && (get_version_major() >= 10)) {
        # acpica-tools package is in CRB in Rocky 10+
        assert_script_run "dnf config-manager --set-enabled crb";
    }

    # install bulk of available updates to prevent issues in cockpit
    # NOTE: The excessively long timeout is to handle both late release cycle
    # update volume as well as slower download speeds for repositories in
    # staging that are not backed by CDN.
    assert_script_run 'dnf -y update', 900;

    # ensure cockpit is installed
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
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
