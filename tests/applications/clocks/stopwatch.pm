use base "installedtest";
use strict;
use testapi;
use utils;

# I as a user want to be able to measure time using stopwatch.

sub run {
    my $self = shift;

    # Click on the Stopwatch button.
    assert_and_click("clocks_button_stopwatch");

    # Start the stopwatch, pause it, resume, and clear.
    assert_and_click("clocks_stopwatch_button_start");
    # Wait some time and pause the stopwatch, read the
    # time.
    sleep(20);
    assert_and_click("clocks_stopwatch_button_pause", timeout => 2);
    assert_screen("clocks_stopwatch_time_reached");
    # Resume the measurement.
    assert_and_click("clocks_stopwatch_button_resume");
    sleep(10);
    # Press pause and read the time.
    assert_and_click("clocks_stopwatch_button_pause", timeout => 2);
    assert_screen("clocks_stopwatch_secondtime_reached");
    # Clear the stopwatch and check you can start it again.
    assert_and_click("clocks_stopwatch_button_clear");
    assert_screen("clocks_stopwatch_button_start");

    # Start the stopwatch, count several laps and assert.
    assert_and_click("clocks_stopwatch_button_start");
    sleep(10);
    assert_and_click("clocks_stopwatch_button_lap");
    sleep(10);
    assert_and_click("clocks_stopwatch_button_lap");
    sleep(10);
    assert_and_click("clocks_stopwatch_button_lap");
    assert_and_click("clocks_stopwatch_button_pause");
    assert_screen("clocks_stopwatch_laps_count");
    assert_screen("clocks_stopwatch_laps_times");
    assert_screen("clocks_stopwatch_laps_deltas");
}

sub test_flags {
    # Rollback when tests are over.
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
