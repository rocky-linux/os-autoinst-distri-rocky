use base "installedtest";
use strict;
use testapi;
use utils;
use packagetest;

sub run {
    my $self = shift;
    my $desktop = get_var('DESKTOP');
    my $relnum = get_release_number;
    my $version_major = get_version_major;
    # use a tty console for repo config and package prep
    $self->root_console(tty => 3);
    assert_script_run 'dnf config-manager --set-disabled updates-testing';
    prepare_test_packages;
    # get back to the desktop
    desktop_vt;

    # run the updater
    # FIXME: when F33 goes EOL, remove all the KDE < F34 stuff below
    # and drop 'desktop_package_tool_update' tag from
    # desktop_update_notification_systray-kde-20200929.json
    if ($desktop eq 'kde') {
        # KDE team tells me until F34 the 'preferred' update method
        # was the systray applet...
        if (($relnum < 34) || ($version_major < 9)) {
            # get rid of notifications which get in the way of the things
            # we need to click
            click_unwanted_notifications;
            assert_and_click 'desktop_expand_systray';
        }
        else {
            # ...from F34 onwards, it's Plasma Discover app
            menu_launch_type('discover');
        }
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
    # go to the 'update' interface. For GNOME or KDE on F34+, we
    # may be waiting some time at a 'Software catalog is being
    # loaded' screen.
    if ($desktop eq 'gnome' || ($desktop eq 'kde' && $relnum > 33)) {
        for my $n (1 .. 5) {
            last if (check_screen 'desktop_package_tool_update', 120);
            mouse_set 10, 10;
            mouse_hide;
        }
    }
    assert_and_click 'desktop_package_tool_update';
    # wait for things to settle if e.g. GNOME is refreshing
    wait_still_screen 5, 90;
    # depending on automatic update checks, 'apply' or 'download' may
    # already be visible at this point, we may not need to refresh
    assert_screen ['desktop_package_tool_update_apply', 'desktop_package_tool_update_download', 'desktop_package_tool_update_refresh'], 120;
    my $tags = ['desktop_package_tool_update_download', 'desktop_package_tool_update_apply'];
    # Apply updates, moving the mouse every two minutes to avoid the
    # idle screen blank kicking in. Depending on whether this is KDE
    # or GNOME and what Fedora release, we may see 'apply' right away,
    # or 'download' then 'apply', or we may only see 'refresh' and
    # need to click it first
    for (my $n = 1; $n < 6; $n++) {
        if (check_screen $tags, 120) {
            # if we see 'apply', we're done here, quit out of the loop
            last if (match_has_tag 'desktop_package_tool_update_apply');
            # if we see 'download', let's hit it, and continue waiting
            # for apply (only)
            wait_screen_change { click_lastmatch; };
            $n -= 1 if ($n > 2);
            $tags = ['desktop_package_tool_update_apply'];
            next;
        }
        elsif ($n == 1) {
            # if we're in the first iteration of this loop and we can't
            # see apply or download, that means we can only see refresh
            # and should click it
            click_lastmatch;
            sleep 2;
        }
        # move the mouse to stop the screen blanking on idle
        mouse_set 10, 10;
        mouse_hide;
    }
    # Magic wait, clicking this right after the last click sometimes
    # goes wrong
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
    elsif ($desktop eq 'kde' && $relnum > 33) {
        # KDE does offline updates now, we have to trigger the reboot
        # FIXME: also sometimes the update apply button just doesn't
        # work, so keep clicking till it does:
        # https://bugzilla.redhat.com/show_bug.cgi?id=1943943
        for my $n (1 .. 10) {
            sleep 2;
            assert_screen ['kde_offline_update_reboot', 'desktop_package_tool_update_apply'];
            # break out if we reached the reboot button
            last if (match_has_tag 'kde_offline_update_reboot');
            # otherwise, try refresh and apply or reboot
            assert_and_click 'desktop_package_tool_update_refresh';
            assert_screen ['kde_offline_update_reboot', 'desktop_package_tool_update_apply'];
            last if (match_has_tag 'kde_offline_update_reboot');
            click_lastmatch;
        }
        assert_and_click 'kde_offline_update_reboot';
        boot_to_login_screen;
    }
    else {
        assert_screen 'desktop_package_tool_update_done', 180;
    }
    # back to console to verify updates
    $self->root_console(tty => 3);
    verify_updated_packages;
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
