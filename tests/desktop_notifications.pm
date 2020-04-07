use base "installedtest";
use strict;
use testapi;
use utils;
use packagetest;

# This test sort of covers QA:Testcase_desktop_update_notification
# and QA:Testcase_desktop_error_checks . If it fails, probably *one*
# of those failed, but we don't know which (deciphering which is
# tricky and involves likely-fragile needles to try and figure out
# what notifications we have).

sub run {
    my $self = shift;
    my $desktop = get_var("DESKTOP");
    # for the live image case, handle bootloader here
    if (get_var("BOOTFROM")) {
        do_bootloader(postinstall=>1, params=>'3');
    }
    else {
        do_bootloader(postinstall=>0, params=>'3');
    }
    boot_to_login_screen;
    $self->root_console(tty=>3);
    # ensure we actually have some package updates available
    prepare_test_packages;
    if ($desktop eq 'gnome') {
        # On GNOME, move the clock forward if needed, because it won't
        # check for updates before 6am(!)
        my $hour = script_output 'date +%H';
        if ($hour < 6) {
            script_run 'systemctl stop chronyd.service ntpd.service';
            script_run 'systemctl disable chronyd.service ntpd.service';
            script_run 'systemctl mask chronyd.service ntpd.service';
            assert_script_run 'date --set="06:00:00"';
        }
        if (get_var("BOOTFROM")) {
            # Also reset the 'last update notification check' timestamp
            # to >24 hours ago (as that matters too)
            my $now = script_output 'date +%s';
            my $yday = $now - 48*60*60;
            # have to log in as the user to do this
            script_run 'exit', 0;
            console_login(user=>get_var('USER_LOGIN', 'test'), password=>get_var('USER_PASSWORD', 'weakpassword'));
            script_run "gsettings set org.gnome.software check-timestamp ${yday}", 0;
            wait_still_screen 3;
            script_run "gsettings get org.gnome.software check-timestamp", 0;
            wait_still_screen 3;
            script_run 'exit', 0;
            console_login(user=>'root', password=>get_var('ROOT_PASSWORD', 'weakpassword'));
        }
    }
    assert_script_run 'systemctl isolate graphical.target';
    # we trust systemd to switch us to the right tty here
    if (get_var("BOOTFROM")) {
        assert_screen 'graphical_login';
        wait_still_screen 3;
        # GDM 3.24.1 dumps a cursor in the middle of the screen here...
        mouse_hide;
        if (get_var("DESKTOP") eq 'gnome') {
            # we have to hit enter to get the password dialog
            send_key "ret";
        }
        assert_screen "graphical_login_input";
        type_very_safely get_var("USER_PASSWORD", "weakpassword");
        send_key 'ret';
    }
    else {
        # the "live boot" branch; we may need to work around
        # https://bugzilla.redhat.com/show_bug.cgi?id=1821499
        # we should wind up at desktop now, but with that bug we
        # hit GDM instead
        if (check_screen "graphical_login", 30) {
            record_soft_failure "Hit GDM unexpectedly - #1821499";
            send_key 'ret';
        }
    }
    check_desktop_clean(tries=>30);
    # now, WE WAIT. this is just an unconditional wait - rather than
    # breaking if we see an update notification appear - so we catch
    # things that crash a few minutes after startup, etc.
    for my $n (1..16) {
        sleep 30;
        mouse_set 10, 10;
        mouse_hide;
    }
    if ($desktop eq 'gnome') {
        # of course, we have no idea what'll be in the clock, so we just
        # have to click where we know it is
        mouse_set 512, 10;
        mouse_click;
        if (get_var("BOOTFROM")) {
            # we should see an update notification and no others
            assert_screen "desktop_update_notification_only";
        }
        else {
            # for the live case there should be *no* notifications
            assert_screen "desktop_no_notifications";
        }
    }
    elsif ($desktop eq 'kde') {
        if (get_var("BOOTFROM")) {
            assert_screen "desktop_update_notification";
            # this is the case from F30 and earlier where we know this
            # was the *only* notification; at this point we've passed
            return if match_has_tag "desktop_update_notification_only";
            # otherwise, we need to close the update notification(s)
            # then check there are no others; see
            # https://bugzilla.redhat.com/show_bug.cgi?id=1730482 for
            # KDE showing multiple notifications
            my @closed = click_unwanted_notifications;
            if (grep {$_ eq 'akonadi'} @closed) {
                # this isn't an SELinux denial or a crash, so it's not
                # a hard failure...
                record_soft_failure "stuck akonadi_migration_agent popup - RHBZ #1716005";
            }
            my @upnotes = grep {$_ eq 'update'} @closed;
            if (scalar @upnotes > 1) {
                # Also not a hard failure, but worth noting
                record_soft_failure "multiple update notifications - RHBZ #1730482";
            }
        }
        # the order and number of systray icons varies in KDE, so we
        # can't really just use a systray 'no notifications' needle.
        # instead open up the 'extended systray' thingy and click on
        # the notifications bit
        assert_and_click 'desktop_expand_systray';
        assert_and_click 'desktop_systray_notifications';
        # In F28+ we seem to get a network connection notification
        # here. Let's dismiss it.
        if (check_screen 'desktop_network_notification', 5) {
            click_lastmatch;
        }
        # In F32+ we may also get an 'akonadi did something' message
        if (check_screen 'akonadi_migration_notification', 5) {
            click_lastmatch;
        }
        # on live path, we should not have got any other notification;
        # on installed path, we saw an update notification and closed
        # it, and now there should be no *other* notifications
        assert_screen "desktop_no_notifications";
    }
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
