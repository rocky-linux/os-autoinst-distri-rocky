use base "installedtest";
use strict;
use testapi;
use utils;

# This will test that user can switch between two applications
# using the navigation combo Alt-tab.

sub switch_to_app {
    # This will use Alt-tab to switch to the desired application.
    # Use the name of the application and the direction in which
    # the search should be performed, either forward or backward.
    my ($application, $dir, $fullscreen) = @_;
    $application =~ s/ /_/g;
    # If we want to search backwards, we will hold the shift key.
    if ($dir eq "backward") {
        hold_key("shift");
    }
    # Then we hold the alt key to either form shift-alt or just alt
    # key combo.
    hold_key("alt");
    # We will send tab, until we have arrived at the correct icon
    send_key_until_needlematch("navigation_navibar_$application", "tab", 10, 2);
    # We will release the alt key.
    release_key("alt");
    #
    if ($dir eq "backward") {
        release_key("shift");
    }
    my $needle = $fullscreen ? "navigation_${application}_fullscreen" : "apps_run_${application}";
    assert_screen($needle);
    if ($fullscreen) {
        die "Not fullscreen!" if (check_screen("apps_menu_button"));
    }
}

sub check_hidden {
    # This function checks that the application
    # is no longer fully displayed on the screen,
    # because it has been hidden (minimized).
    my $app = shift;
    # First, let us wait until the screen settles.
    wait_still_screen(3);
    # If the application is still shown, let's die.
    die("The application seems not to have been minimized.") if (check_screen("apps_run_$app"));
}

sub run {
    my $self = shift;

    ### Switch between two applications
    menu_launch_type("files");
    assert_screen("apps_run_files");
    menu_launch_type("text editor");
    assert_screen('apps_run_texteditor');
    # From the setup script, we should be seeing the editor
    # window.
    # Switch to the other application.
    send_key("alt-tab");
    assert_screen("apps_run_files");

    # Switch back
    send_key("alt-tab");
    assert_screen("apps_run_texteditor");

    # move the window to the left to be sure both will be visible
    # for clicking
    send_key("super-left");
    # Switch by clicking on the certain application.
    assert_and_click("files_inactive");
    assert_screen("apps_run_files");
    assert_and_click("editor_inactive");
    assert_screen("apps_run_texteditor");

    ### Switch between more applications

    # Start more applications.
    menu_launch_type("clocks", maximize => 1);
    # Sometime, Clocks start with an access request,
    # deny it.
    if (check_screen('grant_access', 5)) {
        send_key('ret');
    }
    assert_screen('apps_run_clocks');
    menu_launch_type("calculator", maximize => 1);
    assert_screen('apps_run_calculator');
    menu_launch_type("terminal", maximize => 1);
    assert_screen('apps_run_terminal');

    ## Going forwards
    # Switch to Calculator using alt-tab
    switch_to_app("calculator", "forward");
    # Switch to Clocks using alt-tab
    switch_to_app("clocks", "forward");

    ## Going backwards
    # Switch to Nautilus using shift-alt-tab
    switch_to_app("files", "backward");
    # Switch to Terminal using shift-alt-tab
    switch_to_app("terminal", "backward");

    ### Switch to and from a full screen application
    # We will make Terminal to full screen
    send_key("f11");
    wait_still_screen(3);

    # Switch to Editor
    switch_to_app("texteditor", "forward");

    # Switch to Terminal (fullscreen)
    switch_to_app("terminal", "backward", 1);

    # Switch to Editor
    switch_to_app("texteditor", "forward");

    ### Switch between minimised apps.
    # Minimise Editor
    send_key("super-h");
    # Check that the application has minimised.
    check_hidden("texteditor");

    # Switch to Clocks
    switch_to_app("clocks", "forward");
    # Minimise Clocks
    send_key("super-h");
    # Check that the application has minimised.
    check_hidden("clocks");

    # Switch to Editor
    switch_to_app("texteditor", "forward");

    # Switch to Clocks
    switch_to_app("clocks", "forward");
}

sub test_flags {
    return {always_rollback => 1};
}

1;

# vim: set sw=4 et:



