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
    my $relnum = get_release_number;
    my $version_major = get_version_major;
    # for the live image case, handle bootloader here
    if (get_var("BOOTFROM")) {
        do_bootloader(postinstall=>1, params=>'3');
    }
    else {
        do_bootloader(postinstall=>0, params=>'3');
    }
    boot_to_login_screen;
    # use tty1 to avoid RHBZ #1821499 on F32 Workstation live
    $self->root_console(tty=>1);
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
            # Set a bunch of update checking-related timestamps to
            # two days ago or two weeks ago to try and make sure we
            # get notifications, see:
            # https://wiki.gnome.org/Design/Apps/Software/Updates#Tentative_Design
            my $now = script_output 'date +%s';
            my $yyday = $now - 2*24*60*60;
            my $longago = $now - 14*24*60*60;
            # have to log in as the user to do this
            script_run 'exit', 0;
            console_login(user=>get_var('USER_LOGIN', 'test'), password=>get_var('USER_PASSWORD', 'weakpassword'));
            script_run "gsettings set org.gnome.software check-timestamp ${yyday}", 0;
            script_run "gsettings set org.gnome.software update-notification-timestamp ${longago}", 0;
            script_run "gsettings set org.gnome.software online-updates-timestamp ${longago}", 0;
            script_run "gsettings set org.gnome.software upgrade-notification-timestamp ${longago}", 0;
            script_run "gsettings set org.gnome.software install-timestamp ${longago}", 0;
            wait_still_screen 5;
            script_run 'exit', 0;
            console_login(user=>'root', password=>get_var('ROOT_PASSWORD', 'weakpassword'));
        }
    }
    # can't use assert_script_run here as long as we're on tty1
    type_string "systemctl isolate graphical.target\n";
    # we trust systemd to switch us to the right tty here
    if (get_var("BOOTFROM")) {
        assert_screen 'graphical_login';
        wait_still_screen 10, 30;
        # GDM 3.24.1 dumps a cursor in the middle of the screen here...
        mouse_hide;
        if (get_var("DESKTOP") eq 'gnome') {
            # we have to hit enter to get the password dialog, and it
            # doesn't always work for some reason so just try it three
            # times
            send_key_until_needlematch("graphical_login_input", "ret", 3, 5);
        }
        assert_screen "graphical_login_input";
        type_very_safely get_var("USER_PASSWORD", "weakpassword");
        send_key 'ret';
    }
    check_desktop(timeout=>90);
    # now, WE WAIT. Because KDE on F34+ shows a notification only
    # briefly we will keep an eye out and record if we saw it (logic
    # around this comes later). But we wait the whole ten minutes even
    # if we see it  so we catch any unwanted notifications that appear
    # shortly after boot
    my $seen = 0;
    for my $n (1..16) {
        $seen = 1 if (check_screen "desktop_update_notification", 30);
        mouse_set 20, 20;
        send_key "spc";
        mouse_hide;
    }
    if ($desktop eq 'gnome') {
        # click the clock to show notifications. of course, we have no
        # idea what'll be in the clock, so we just have to click where
        # we know it is
        mouse_set 512, 10;
        mouse_click;
    }
    if ($desktop eq 'kde') {
        if (get_var("BOOTFROM")) {
            # first check the systray update notification is there
            assert_screen "desktop_update_notification_systray";
        }
        # now open the notifications view in the systray
        if (check_screen 'desktop_icon_notifications') {
            # this is the little bell thing KDE sometimes shows if
            # there's been a notification recently...
            click_lastmatch;
        }
        else {
            # ...otherwise you have to expand the systray and click
            # "Notifications"
            assert_and_click 'desktop_expand_systray';
            assert_and_click 'desktop_systray_notifications';
        }
        # In F32+ we may get an 'akonadi did something' message
        if (check_screen 'akonadi_migration_notification', 5) {
            click_lastmatch;
        }
    }
    if (get_var("BOOTFROM")) {
        if ($desktop eq 'kde' && (($relnum > 33) || ($version_major > 8))) {
            # there is not always a permanent notification in F34+,
            # if we don't see one, check we saw the transient one
            # earlier. FIXME: maybe drop the 'transient' path here
            # if the permanent notification seems to be reliably
            # back after 2021-06-13 Rawhide?
            assert_screen ["desktop_no_notifications", "desktop_update_notification_only"];
            if (match_has_tag "desktop_no_notifications") {
                die "No update notification was shown!" unless $seen;
            }
        }
        else {
            # we should see an update notification and no others
            assert_screen "desktop_update_notification_only";
        }
    }
    else {
        # for the live case there should be *no* notifications
        assert_screen "desktop_no_notifications";
        if ($desktop eq 'kde' && $relnum > 33) {
            # and no tray icon either
            die "Systray update notification should not be present on live!" if (check_screen "desktop_update_notification_systray");
            die "Transient notification should not be shown on live!" if $seen;
        }
    }
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
