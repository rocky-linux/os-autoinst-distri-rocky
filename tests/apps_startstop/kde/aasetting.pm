use base "installedtest";
use strict;
use testapi;
use utils;

# This sets the KDE desktop background to plain black, to avoid
# needle match problems caused by transparency.

sub run {
    my $self = shift;
    # Run the Desktop settings
    hold_key 'alt';
    send_key 'd';
    send_key 's';
    release_key 'alt';
    # Select type of background
    assert_and_click "deskset_select_type";
    wait_still_screen 2;
    # Select plain color type
    assert_and_click "deskset_plain_color";
    wait_still_screen 2;
    # Open colors selection
    assert_and_click "deskset_select_color";
    wait_still_screen 2;
    # Select black
    assert_and_click "deskset_select_black";
    wait_still_screen 2;
    # Confirm
    assert_and_click "kde_ok";
    wait_still_screen 2;
    # Close the application
    assert_and_click "kde_ok";
    # If Updates Available notification is shown, we want
    # to get rid of that, because it can be later displayed
    # over some applications preventing OpenQA to find
    # correct buttons, which creates false positives.
    if (check_screen "desktop_update_notification_popup", 10) {
        assert_and_click "desktop_update_notification_popup";
    }
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}


1;

# vim: set sw=4 et:
