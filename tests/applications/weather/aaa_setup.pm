use base "installedtest";
use strict;
use testapi;
use utils;

# This script will start the Gnome Weather application and save
# the image for all subsequent tests.

sub run {
    my $self = shift;

    # Install Weather with flatpak
    # NOTE: This will trigger an authentication (perhaps 2x) in desktop_vt()
    $self->root_console(tty => 3);
    assert_script_run("flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo");
    assert_script_run "flatpak install -y flathub org.gnome.weather",300;

    # Exit the terminal
    desktop_vt;

    # Set the update notification timestamp
    set_update_notification_timestamp();

    # Start the Application
    # We need to do extra checking, therefore we want to start simple
    # and not use the menu_launch_type, so we do the checks manually.
    menu_launch_type("weather");

    assert_screen ["apps_run_weather", "grant_access"];
    # sometimes we match apps_run_weather for a split second before
    # grant_access appears, so handle that
    wait_still_screen 3;
    assert_screen ['apps_run_weather', 'grant_access'];

    # give access rights if asked
    if (match_has_tag 'grant_access') {
        click_lastmatch;
        assert_screen 'apps_run_weather';
    }

    # Make it fill the entire window.
    send_key("super-up");
    wait_still_screen(2);

    # Search for the city, different from the default one
    # as the default one can differ between zones.
    if (check_screen("weather_search_city")) {
        click_lastmatch;
    }
    type_very_safely("Edinburgh");
    assert_and_click("weather_select_city");

    # check we wind up on the hourly view, then let things settle
    # before snapshotting
    assert_screen("weather_report_hourly");
    wait_still_screen 3;
}

sub test_flags {
    # If this test fails, there is no need to continue.
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:

