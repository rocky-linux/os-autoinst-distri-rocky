use base "installedtest";
use strict;
use testapi;
use utils;

# This script checks that Gnome Calculator shows About.

sub run {
    my $self = shift;
    # Let's wait until everything settles down properly
    # before we start testing.
    sleep 5;
    # Open the menu and click on the About item.
    assert_and_click("gnome_burger_menu");
    wait_still_screen(2);
    assert_and_click("calc_menu_about");
    # Check that it is shown.
    assert_screen("calc_about_shown");
    # Click on the Credits button and check that it shows.
    unless (check_screen("gnome_button_credits", 30)) {
        send_key("pgdn");
        assert_screen("gnome_button_credits", 15);
        record_soft_failure("https://gitlab.gnome.org/GNOME/gnome-calculator/-/issues/419");
    }
    click_lastmatch;
    assert_screen("calc_credits_shown");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:

