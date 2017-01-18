use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self=shift;
    # run firefox and login to cockpit
    start_cockpit(1);
    # go to the logs screen
    assert_and_click "cockpit_logs";
    # the date dropdown changes and messes with the button locations, so wait
    wait_still_screen 2;
    assert_and_click "cockpit_logs_notices";
    wait_still_screen 2;
    # assume there's an entry, click it
    assert_and_click "cockpit_logs_notices_entry";
    # check we get to the appropriate detail screen
    assert_screen "cockpit_logs_notices_detail";
    # go to the services screen
    assert_and_click "cockpit_services";
    wait_still_screen 2;
    # assume auditd is there, click it
    assert_and_click "cockpit_services_auditd";
    # check we get to the appropriate detail screen
    assert_screen "cockpit_services_auditd_detail";
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
