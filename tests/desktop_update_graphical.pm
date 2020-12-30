use base "installedtest";
use strict;
use testapi;
use utils;
use packagetest;

sub run {
    my $self = shift;
    my $desktop = get_var('DESKTOP');
    # use a tty console for repo config and package prep
    $self->root_console(tty=>3);
    assert_script_run 'dnf config-manager --set-disabled updates-testing';
    prepare_test_packages;
    # get back to the desktop
    desktop_vt;

    # run the updater
    if ($desktop eq 'kde') {
        # get rid of notifications which get in the way of the things
        # we need to click
        click_unwanted_notifications;
        # KDE team tells me the 'preferred' update method is the
        # systray applet
        assert_and_click 'desktop_expand_systray';
    }
    else {
        # this launches GNOME Software on GNOME, dunno for any other
        # desktop yet
        sleep 3;
        menu_launch_type('update');
    }
    # GNOME Software has a welcome screen, get rid of it if it shows
    # up (but don't fail if it doesn't, we're not testing that)
    if ($desktop eq 'gnome' && check_screen 'gnome_software_welcome', 10) {
        send_key 'ret';
    }
    # go to the 'update' interface. For GNOME, we may be waiting
    # some time at a 'Software catalog is being loaded' screen.
    if ($desktop eq 'gnome') {
        for my $n (1..5) {
            last if (check_screen 'desktop_package_tool_update', 120);
            mouse_set 10, 10;
            mouse_hide;
        }
    }
    assert_and_click 'desktop_package_tool_update';
    # depending on automatic update checks, 'apply' or 'download' may
    # already be visible at this point, we may not need to refresh
    unless (check_screen ['desktop_package_tool_update_apply', 'desktop_package_tool_update_download'], 10) {
        # refresh updates
        assert_and_click('desktop_package_tool_update_refresh', timeout=>120);
    }
    # wait for refresh, then apply updates, moving the mouse every two
    # minutes to avoid the idle screen blank kicking in. Depending on
    # whether this is KDE or GNOME and what Fedora release, we may see
    # 'apply' right away, or 'download' then 'apply'.
    my $tags = ['desktop_package_tool_update_download', 'desktop_package_tool_update_apply'];
    for (my $n = 1; $n < 6; $n++) {
        if (check_screen $tags, 120) {
            # if we see 'apply', we're done here, quit out of the loop
            last if (match_has_tag 'desktop_package_tool_update_apply');
            # if we see 'download', we're in the GNOME Software 3.30.5+
            # two-step process - let's hit it, and continue waiting for
            # for apply (only)
            wait_screen_change { click_lastmatch; };
            $n -= 1 if ($n > 1);
            $tags = ['desktop_package_tool_update_apply'];
            next;
        }
        # move the mouse to stop the screen blanking on idle
        mouse_set 10, 10;
        mouse_hide;
    }
    # KDE annoyingly pops the notification up right over the install
    # button, which doesn't help...wait for it to go away. Let's also
    # wait on GNOME, as we've had tests fail at this point for no
    # obvious reason, a wait may help.
    wait_still_screen 5;
    assert_and_click 'desktop_package_tool_update_apply';
    # on GNOME, wait for reboots.
    if ($desktop eq 'gnome') {
        # handle reboot confirm screen which pops up when user is
        # logged in (but don't fail if it doesn't as we're not testing
        # that)
        if (check_screen 'gnome_reboot_confirm', 15) {
            send_key 'tab';
            send_key 'ret';
        }
        boot_to_login_screen;
    }
    else {
        assert_screen 'desktop_package_tool_update_done', 180;
    }
    # back to console to verify updates
    $self->root_console(tty=>3);
    verify_updated_packages;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
