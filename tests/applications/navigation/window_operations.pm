use base "installedtest";
use strict;
use testapi;
use utils;

# This will test that
# - window can be maximized
# - window can be minimized
# - window can be restored to the previous size
# - window can be moved across screen
# - window can be tiled left, right, up, down
# - window can be resized
# - window can be closed

sub use_menu {
    my $selection = shift;
    assert_and_click("calculator_title_bar", button => 'right');
    assert_and_click("calculator_context_$selection");
    wait_still_screen(2);
}

sub run {
    my $self = shift;
    my $version = get_release_number();
    sleep(5);

    # Let's start a new application. We'll go with Calculator,
    # because it has a small window that fits nicely into
    # a small screen we use in openQA.
    menu_launch_type("calculator");
    assert_screen("apps_run_calculator");

    # Maximize the application - right click and select from
    # the context menu.
    use_menu('maximize');
    assert_screen("calculator_maximized");

    # Restore the application - right click and select from
    # the context menu.
    use_menu('restore');
    # If we are still maximized, it did not work -> die
    if (check_screen('calculator_maximized', timeout => 5)) {
        die("The application should have been restored via menu, but is not.");
    }

    # Hide the application - right click and select from
    # the context menu.
    use_menu('hide');
    # Check that we see the application, if so, it did not work
    # and we die.
    if (check_screen('apps_run_calculator', timeout => 5)) {
        die("The application should have been hidden via menu, but is not.");
    }

    # Unhide the application
    send_key('super');
    sleep(2);
    assert_and_click('calculator_select_hidden');
    assert_screen('apps_run_calculator');

    # Get focus
    assert_and_click("calculator_upper_edge");
    # Maximise the application using a double click.
    assert_and_dclick("calculator_upper_edge");
    assert_screen("calculator_maximized");

    # Restore using a double click.
    assert_and_dclick("calculator_upper_edge");
    if (check_screen("calculator_maximized", timeout => 5)) {
        die("The application should have been restored via click, but is not.");
    }

    # Maximise the application using a short cut
    send_key("super-up");
    assert_screen('calculator_maximized');

    # Restore using short cut
    send_key("super-down");
    if (check_screen("calculator_maximized")) {
        die("The application should have been restored via keyboard, but is not.");
    }

    # Tile the application to left side
    send_key("super-left");
    assert_screen("calculator_tiled_left");

    # Tile the application to the right side
    send_key("super-right");
    assert_screen("calculator_tiled_right");

    # Close the window.
    send_key("alt-f4");
    check_desktop();
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:



