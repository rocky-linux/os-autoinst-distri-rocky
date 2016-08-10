use base "installedtest";
use strict;
use testapi;

sub run {
    my $self=shift;
    # check cockpit appears to be enabled and running and firewall is setup
    assert_script_run 'systemctl is-enabled cockpit.socket';
    assert_script_run 'systemctl is-active cockpit.socket';
    assert_script_run 'firewall-cmd --query-service cockpit';
    # we don't want updates-testing for validation purposes
    assert_script_run 'dnf config-manager --set-disabled updates-testing';
    # install a desktop and firefox so we can actually try it
    assert_script_run 'dnf -y --nogpgcheck groupinstall "base-x"', 300;
    assert_script_run 'dnf -y --nogpgcheck install firefox', 120;
    $self->start_cockpit(0);
    # quit firefox (return to console)
    send_key "ctrl-q";
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
