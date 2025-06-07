use base "installedtest";
use strict;
use testapi;
use utils;

# This will test that
# - application can be toggled between full screen and normal view

sub run {
    my $self = shift;
    # Settle in for a while
    sleep(5);
    # The full screen is not supported by any application, but it
    # is supported by several, such as Terminal.
    menu_launch_type("terminal", maximize => 1);
    # If we see prompt, everything is ok.
    assert_screen("terminal_prompt");

    # When the application is maximised but not full screen,
    # the panel controls should be visible.
    assert_screen("panel_controls");

    # F11 will trigger the full screen mode, the panel controls
    # should no longer be visible, but the page content should
    # still be visible.
    send_key("f11");

    # We still need to see the prompt.
    assert_screen("terminal_prompt");
    # But we should not see the panels.
    if (check_screen("panel_controls")) {
        die("It seems that full screen mode has not been triggered correctly.");
    }

    # Another F11 will trigger that full screen mode off. The panel
    # controls will be visible again and the page content, too.
    send_key("f11");
    assert_screen("terminal_prompt");
    assert_screen("panel_controls");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:



