use base "installedtest";
use strict;
use testapi;
use utils;

# This part of the suite tests that Evince is able to display content in a two-page mode.

sub run {
    my $self = shift;

    # Click on the Zoom menu to change a different zoom for next steps.
    assert_and_click("evince_change_zoom", button => "left", timeout => 30);

    # Select the Fit Width option to be able to see the whole layout.
    assert_and_click("evince_select_zoom_fitwidth", button => "left", timeout => 30);

    #Dismiss the dialogue
    send_key("esc");

    # Enter the menu
    assert_and_click("gnome_burger_menu", button => "left", timeout => 30);

    # Select the Dual mode
    assert_and_click("evince_menu_dual", button => "left", timeout => 30);

    # Dismiss the menu
    send_key("esc");

    # Check that the content is displayed in dual mode.
    assert_screen("evince_dual_mode", timeout => 30);
}

sub test_flags {
    return {always_rollback => 1};
}

1;
