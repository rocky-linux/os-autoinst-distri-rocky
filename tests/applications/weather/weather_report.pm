use base "installedtest";
use strict;
use testapi;
use utils;

# This script will start the Gnome Weather application and save
# the image for all subsequent tests.

sub run {
    my $self = shift;

    # The application should have started in the Hourly regime
    # so let us check that it really is in this regime.
    assert_screen("weather_report_hourly");
    # Assert that a big icon is visible.
    assert_screen("weather_icon_current");
    # Assert that one of the smaller icons is available.
    assert_screen("weather_icon_smaller");

    # Change the report to a daily report.
    assert_and_click("weather_button_daily");
    # Assert that the view changed to Days and not Hours
    assert_screen("weather_report_daily");
    # Assert that a big icon is visible.
    assert_screen("weather_icon_current");
    # Assert that one of the smaller icons is available.
    assert_screen("weather_icon_smaller");
}

sub test_flags {
    # If this test fails, there is no need to continue.
    return {no_rollback => 1};
}

1;

# vim: set sw=4 et:

