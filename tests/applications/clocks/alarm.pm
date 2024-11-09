use base "installedtest";
use strict;
use testapi;
use utils;

# I as a user want to be able to add, edit and remove alarms.

sub run {
    my $self = shift;

    # Click on the Alarm button.
    assert_and_click("clocks_button_alarm");

    # Add a new alarm using the Add Alarm button
    assert_and_click("clocks_button_add_alarm");
    assert_and_click("clocks_alarm_hour");
    wait_still_screen 2;
    send_key("ctrl-a");
    wait_still_screen(2);
    type_very_safely("09");
    send_key("tab");
    type_very_safely("04");
    assert_and_click("clocks_set_snooze");
    assert_and_click("clocks_set_snooze_time");
    assert_and_click("gnome_add_button");
    assert_screen("clocks_alarm_active");

    # Wait until the alarm goes on, two buttons will be shown. This should not take
    # more than three minutes.
    # A snooze button should become visible, click it.
    assert_and_click("clocks_button_alarm_snooze", timeout => 240);
    assert_screen("clocks_alarm_snooze_confirmed");
    # After another minute or so, the alarm should ring again.
    # This time we will use the stop button to stop it.
    assert_and_click("clocks_button_alarm_stop", timeout => 120);
    # Up to 46.0, the alarm would stay active after being stopped; from
    # 46.0 onwards it goes inactive. FIXME this can be simplified to
    # assume it starts at 'inactive' once we are no longer testing
    # < 46.0 anywhere
    assert_screen(["clocks_alarm_active", "clocks_alarm_inactive"]);
    my $wasactive = match_has_tag("clocks_alarm_active");
    # Now toggle the switch to change its state
    assert_and_click("gnome_button_toggle");
    # whichever state it was in, check it's now in the other
    if ($wasactive) {
        assert_screen("clocks_alarm_inactive");
    }
    else {
        assert_screen("clocks_alarm_active");
    }
    # Delete alarm using the delete button.
    assert_and_click("gnome_button_cross_remove");
    sleep 2;
    if (check_screen(["clocks_alarm_active", "clocks_alarm_inactive"])) {
        die("The alarm should have been deleted but it is still visible in the GUI");
    }


}

sub test_flags {
    # Rollback after test is over.
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:
