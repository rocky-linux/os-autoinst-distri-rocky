use base "installedtest";
use strict;
use testapi;
use packagetest;

sub run {
    my $self = shift;
    my $desktop = get_var('DESKTOP');
    # use a tty console for repo config and package prep
    $self->root_console(tty=>3);
    assert_script_run 'dnf config-manager --set-disabled updates-testing';
    prepare_test_packages;
    # get back to the desktop
    $self->desktop_vt();
    # run the updater
    if ($desktop eq 'kde') {
        # KDE team tells me the 'preferred' update method is the
        # systray applet
        assert_and_click 'desktop_expand_notifications';
    }
    else {
        # this launches GNOME Software on GNOME, dunno for any other
        # desktop yet
        $self->menu_launch_type('update');
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
    assert_and_click 'desktop_package_tool_update_refresh';
    # wait for refresh, then apply updates
    for my $n (1..5) {
        last if (check_screen 'desktop_package_tool_update_apply', 120);
        mouse_set 10, 10;
        mouse_hide;
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
        assert_screen 'graphical_login', 300;
    }
    else {
        assert_screen 'desktop_package_tool_update_done', 180;
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
