use base "installedtest";
use strict;
use testapi;
use utils;

# I as a user want to be able to add, edit and remove timers.

sub run {
    my $self = shift;

    # Click on the Timer button.
    assert_and_click("clocks_button_timer");

    # Add a new alarm using the one minute button
    assert_screen("clocks_timer_page");
    assert_and_click("clocks_button_timer_minute");
    # since GNOME 46, that was a 'quickstart', on older GNOME we
    # have to hit start; remove this when no more F39 testing
    if (check_screen("clocks_button_timer_start", 5)) {
        wait_still_screen(2);
        click_lastmatch;
    }
    sleep(10);
    assert_and_click("clocks_button_timer_pause");
    assert_screen("clocks_timer_paused");
    assert_and_click("clocks_button_timer_start");
    # Wait a minute if the timer goes off.
    assert_screen("clocks_timer_finished", timeout => 60);
    # Delete the timeout
    assert_and_click("gnome_button_delete");
    assert_screen("clocks_timer_page");
}

sub test_flags {
    # Rollback after test is over.
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
