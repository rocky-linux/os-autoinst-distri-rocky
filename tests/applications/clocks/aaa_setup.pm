use base "installedtest";

use strict;
use testapi;
use utils;

# This script will install and start the Gnome Clocks application and save the status
# for any subsequent tests.

sub run {
    my $self = shift;

    # Switch to console
    $self->root_console(tty => 3);

    # Install clocks with flatpak
    # NOTE: This will trigger an authentication (perhaps 2x) in desktop_vt()
    assert_script_run("flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo");
    assert_script_run "flatpak install -y flathub org.gnome.clocks", 300;

    # In Rocky 9 there may be an issue starting Clocks that appears to be resolved in Rocky 10
    # This is a workaround to update the Gnome environment (see below) that requires logout/login
    # to be effective.
    # https://discussion.fedoraproject.org/t/gnome-flatpaks-apps-are-crashing-or-not-opening/133653/26
    if (get_var("DISTRI") eq "rocky" && (get_version_major() < 10))
    {
        my $password = get_var("USER_PASSWORD", "weakpassword");
        assert_script_run('echo "GSK_RENDERER=ngl" >> /etc/environment');

        # Return back
        desktop_vt();

        # Logout/login to use updated environment
        assert_and_click "system_menu_button";
        assert_and_click "leave_button";
        assert_and_click "log_out_entry";
        assert_and_click "log_out_confirm";
        wait_still_screen 5;
        mouse_hide;
        send_key "tab";
        send_key_until_needlematch("graphical_login_input", "ret", 3, 5);
        assert_screen "graphical_login_input";
        type_very_safely $password;
        send_key "ret";
        wait_still_screen 3;

        # Switch to the console
        $self->root_console(tty => 3);
    }

    # Switch off automatic time.
    assert_script_run("timedatectl set-ntp 0");

    # Set the time zone
    assert_script_run("timedatectl set-timezone Europe/Prague");

    # Set the time and date
    assert_script_run("timedatectl set-time '2024-09-09 09:00:00'");

    # Return back
    desktop_vt();

    # Set the update notification timestamp
    set_update_notification_timestamp();

    # Start the Application
    # We need to do extra checking, therefore we want to start simple
    # and not use the menu_launch_type, so we do the checks manually.
    menu_launch_type("clocks");

    assert_screen ["apps_run_clocks", "grant_access"];
    # give access rights if asked
    if (match_has_tag 'grant_access') {
        click_lastmatch;
        assert_screen 'apps_run_clocks';
    }

    # Make it fill the entire window.
    send_key("super-up");
    wait_still_screen(2);
}

sub test_flags {
    # If this test fails, there is no need to continue.
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
