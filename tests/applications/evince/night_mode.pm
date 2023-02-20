use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests that Evince can be switched into night mode.

sub run {
    my $self = shift;

    # Click on the Menu button.
    assert_and_click("gnome_burger_menu", timeout => 30, button => "left");

    # Click on the Night mode to select it.
    assert_and_click("evince_toggle_night_mode", button => "left", timeout => 30);

    # The menu stays opened, so hit Esc to dismiss it.
    send_key("esc");
    wait_still_screen 2;

    # Check that night mode has been activated.
    assert_screen("evince_night_mode", timeout => 30);

}

sub test_flags {
    return {always_rollback => 1};
}

1;
