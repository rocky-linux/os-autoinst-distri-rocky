use base "installedtest";
use strict;
use testapi;
use utils;
use cockpit;

sub run {
    my $self = shift;
    # run firefox and login to cockpit
    start_cockpit(login => 1);
    # go to the logs screen
    assert_and_click "cockpit_logs";
    # the date dropdown changes and messes with the button locations, so wait
    wait_still_screen 2;
    # set priority to info and above in case there are no errors
    assert_and_click "cockpit_logs_priority_text";
    send_key "backspace";
    send_key "backspace";
    send_key "backspace";
    send_key "backspace";
    type_string "info\n";
    wait_still_screen 5;
    # now click an entry
    assert_and_click "cockpit_logs_entry";
    # check we get to the appropriate detail screen
    assert_screen "cockpit_logs_detail";
    # go to the services screen
    assert_and_click "cockpit_services";
    wait_still_screen(timeout => 90, stilltime => 5);
    # click on an entry
    assert_and_click "cockpit_services_entry";
    # check we get to the appropriate detail screen...but this click
    # often gets lost for some reason, so retry it once
    assert_and_click "cockpit_services_entry" unless (check_screen "cockpit_services_detail", 10);
    assert_screen "cockpit_services_detail";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
