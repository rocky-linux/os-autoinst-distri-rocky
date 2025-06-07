use base "installedtest";
use strict;
use testapi;
use utils;

# This will test that
# - a game can be played both full screen or normal

sub send_tab_to_select {
    my $times = shift;
    foreach (1 .. $times) {
        send_key("tab");
        sleep(1);
    }
    send_key("ret");
    sleep(2);
}

sub go_tux {
    my $time = shift // 20;
    while ($time > 0) {
        hold_key("up");
        sleep(1);
        release_key("up");
        sleep(3);
        $time -= 1;
    }
}

sub run {
    my $self = shift;

    # Open the game
    menu_launch_type("tux racer");
    assert_screen("apps_run_tuxracer");

    # Check that it has started in the fullscreen mode.
    if (check_screen("panel_controls")) {
        record_soft_failure("The game should have started in full screen mode.");
    }
    # Select new game. The background changes like hell,
    # and the mouse does not work particularly well
    # without 3d acceleration, so we need to rely
    # on keyboard.
    # Take what is offered.
    send_tab_to_select(2);
    assert_screen('tuxracer_menu');
    # Navigate to start the practice
    send_tab_to_select(1);
    assert_screen('tuxracer_bunnyhill');
    # Navigate to start the race.
    send_tab_to_select(6);
    # Wait a little bit to start the race
    sleep(5);

    # Try to play the game.
    # This is sending a forward key intermittently
    # to slide to slope towards the finish. As it is difficult
    # to make sure Tux finishes in the right place and because
    # the game graphics changes a lot, we need to check whether
    # the screen changes and when it stops changing for some
    # time, we could assume that we have finished the game.
    assert_screen_change(sub { go_tux(30) }, timeout => 10);
    # Then hit to come back to the Race settings.
    send_key('esc');
    assert_screen('tuxracer_bunnyhill');
    sleep(2);
    # One more escape to come to the menu.
    send_key('esc');
    assert_screen('tuxracer_menu');
    # Navigate to Configuration and switch off full screen.
    send_tab_to_select(2);
    # Hit space to switch off full screen.
    send_key('spc');
    sleep(1);
    # Go and press OK.
    send_tab_to_select(7);

    # Now the application should be in non-fs mode,
    # so we should be able to see the Rocky screen
    assert_screen("panel_controls_rocky");

    # Start the game again.
    send_tab_to_select(1);
    assert_screen('tuxracer_bunnyhill_small');
    send_tab_to_select(6);
    sleep(5);

    # Play it as before.
    assert_screen_change(sub { go_tux(30) }, timeout => 10);

    # Send Esc
    send_key('esc');
    assert_screen('tuxracer_bunnyhill_small');

    send_key('esc');
    assert_screen('tuxracer_menu_small');

    # Quit game
    send_tab_to_select(6);
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:



