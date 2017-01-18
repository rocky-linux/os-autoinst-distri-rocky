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
        # KDE team tells me the 'preferred' update method is the
        # systray applet
        assert_and_click 'desktop_expand_systray';
    }
    else {
        # this launches GNOME Software on GNOME, dunno for any other
        # desktop yet
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
    # refresh updates
    assert_and_click 'desktop_package_tool_update_refresh', '', 120;
    # wait for refresh, then apply updates
    for my $n (1..5) {
        last if (check_screen 'desktop_package_tool_update_apply', 120);
        mouse_set 10, 10;
        mouse_hide;
    }
    # KDE annoyingly pops the notification up right over the install
    # button, which doesn't help...wait for it to go away
    if ($desktop eq 'kde') {
        wait_still_screen 5;
    }
    assert_and_click 'desktop_package_tool_update_apply';
    # on GNOME, wait for reboots.
    if ($desktop eq 'gnome') {
        # handle reboot confirm screen which pops up when user is
        # logged in (but don't fail if it doesn't as we're not testing
        # that)
        if (check_screen 'gnome_reboot_confirm', 15) {
            send_key 'ret';
        }
        boot_to_login_screen;
    }
    else {
        # KDE will prompt for authentication if any package is not
        # signed. As of 2016-09-23, puiterwijk claims Rawhide packages
        # will be autosigned 'by Monday', so if this happens, we're
        # going to treat it as a soft fail, indicating the update
        # mechanism works, but a package that should have been signed
        # was not.
        assert_screen ['desktop_package_tool_update_done', 'desktop_package_tool_update_authenticate'], 180;
        if (match_has_tag('desktop_package_tool_update_authenticate')) {
            record_soft_failure;
            type_very_safely get_var('USER_PASSWORD', 'weakpassword');
            send_key 'ret';
            assert_screen 'desktop_package_tool_update_done', 180;
        }
    }
    # back to console to verify updates
    $self->root_console(tty=>3);
    verify_updated_packages;
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
