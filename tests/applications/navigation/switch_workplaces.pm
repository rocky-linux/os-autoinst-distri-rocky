use base "installedtest";
use strict;
use testapi;
use utils;

# This will test that user can switch between two workspaces,
# that we can move an application to another workspace.

sub move_to_workspace {
    # This will use Shift-Ctrl-Alt to move the focused app to
    # the $direction (left or right).
    my $direction = shift;
    wait_screen_change { send_key("shift-ctrl-alt-$direction"); };
    wait_still_screen 5;
}

sub switch_to_workspace {
    # This will use Ctrl-Alt to switch to another workspace
    # using the $direction (left, right)
    my $direction = shift;
    wait_screen_change { send_key("ctrl-alt-$direction"); };
    wait_still_screen 5;
}

sub run {
    my $self = shift;
    # Let us wait here for a couple of seconds to give the VM time to settle.
    # Starting right over might result in erroneous behavior.
    sleep(5);
    menu_launch_type("files", maximize => 1);
    assert_screen('apps_run_files');
    menu_launch_type("text editor", maximize => 1);
    assert_screen('apps_run_texteditor');

    # The focused application should be the Editor, so let's check it is
    # visible on the beginning screen. Then switch to another workplace.
    # This one should be empty, therefore checking for the Editor should fail.
    # The opposite will be true, when we switch back
    assert_screen("apps_run_texteditor");
    switch_to_workspace("right");
    die("The workspaces were not switched!") if (check_screen("apps_run_texteditor"));

    switch_to_workspace("left");
    die("The workspaces were not switched") unless (check_screen("apps_run_texteditor"));

    # Now, we will move the focused application (Editor) to the second workspace.
    # The application will be still visible there. When we switch back, the application
    # will no longer be visible on the first workspace and will uncover Nautilus and
    # we check that it is there. We will also enter the Activitities mode and will check
    # that currently three workspaces can be used (top bar of the screen).
    move_to_workspace("right");
    die("The application was not moved!") unless (check_screen("apps_run_texteditor"));
    switch_to_workspace("left");
    die("The workspaces were not switched") unless (check_screen("apps_run_files"));
    send_key("super");
    wait_still_screen(2);
    assert_screen("navigation_three_workspaces");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:



