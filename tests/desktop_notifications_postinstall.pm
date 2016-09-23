use base "installedtest";
use strict;
use testapi;
use main_common;
use packagetest;

# This test sort of covers QA:Testcase_desktop_update_notification
# and QA:Testcase_desktop_error_checks . If it fails, probably *one*
# of those failed, but we don't know which (deciphering which is
# tricky and involves likely-fragile needles to try and figure out
# what notifications we have).

sub run {
    my $self = shift;
    # for the live image case, handle bootloader here
    unless (get_var("BOOTFROM")) {
        $self->do_bootloader(postinstall=>0);
    }
    assert_screen "graphical_desktop_clean", 300;
    # ensure we actually have some package updates available
    # we're kinda theoretically racing with the update check here,
    # but we have no great way to handle that especially live; let's
    # just assume we're gonna win
    $self->root_console(tty=>3);
    prepare_test_packages;
    $self->desktop_vt();
    # now, WE WAIT. this is just an unconditional wait - rather than
    # breaking if we see an update notification appear - so we catch
    # things that crash a few minutes after startup, etc.
    for my $n (1..5) {
        sleep 120;
        mouse_set 10, 10;
        mouse_hide;
    }
    my $desktop = get_var("DESKTOP");
    if ($desktop eq 'gnome') {
        # of course, we have no idea what'll be in the clock, so we just
        # have to click where we know it is
        mouse_set 512, 10;
        mouse_click;
    }
    elsif ($desktop eq 'kde' && !get_var("BOOTFROM")) {
        # the order and number of systray icons varies in KDE, so we
        # can't really just use a systray 'no notifications' needle.
        # instead open up the 'extended systray' thingy and click on
        # the notifications bit
        assert_and_click 'desktop_expand_systray';
        assert_and_click 'desktop_systray_notifications';
    }
    if (get_var("BOOTFROM")) {
        # we should see an update notification and no others
        check_screen "desktop_update_notification_only";
    }
    else {
        # for the live case there should be *no* notifications
        assert_screen "desktop_no_notifications";
    }
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
