use base "anacondatest";
use strict;
use testapi;
use utils;


sub _set_root_password {
    # Set root password, unless we don't want to or can't
    # can also hit a transition animation
    wait_still_screen 2;
    my $root_password = get_var("ROOT_PASSWORD") || "weakpassword";
    unless (get_var("INSTALLER_NO_ROOT")) {
        assert_and_click "anaconda_install_root_password";
        if (get_var("MEMCHECK")) {
            # work around https://bugzilla.redhat.com/show_bug.cgi?id=1659266
            unless (check_screen "anaconda_install_root_password_screen", 30) {
                record_soft_failure "UI may be frozen due to brc#1659266";
                assert_screen "anaconda_install_root_password_screen", 300;
            }
        }
        else {
            assert_screen "anaconda_install_root_password_screen";
        }
        # wait out animation
        wait_still_screen 2;
        desktop_switch_layout("ascii", "anaconda") if (get_var("SWITCHED_LAYOUT"));
        if (get_var("IMAGETYPE") eq 'dvd-ostree') {
            # we can't type SUPER safely for ostree installer tests, as
            # the install completes quite fast and if we type too slow
            # the USER CREATION spoke may be blocked
            type_safely $root_password;
            wait_screen_change { send_key "tab"; };
            type_safely $root_password;
        }
        else {
            # these screens seems insanely subject to typing errors, so
            # type super safely. This doesn't really slow the test down
            # as we still get done before the install process is complete.
            type_very_safely $root_password;
            wait_screen_change { send_key "tab"; };
            type_very_safely $root_password;
        }
        # Another screen to test identification on
        my $identification = get_var('IDENTIFICATION');
        if ($identification eq 'true') {
            check_top_bar();
            # we don't check version or pre-release because here those
            # texts appear on the banner which makes the needling
            # complex and fragile (banner is different between variants,
            # and has a gradient so for RTL languages the background color
            # differs; pre-release text is also translated)
        }
        assert_and_click "anaconda_spoke_done";
    }
}

sub _do_root_and_user {
    _set_root_password();
    # Wait out animation
    wait_still_screen 8;
    # Set user details, unless the test is configured not to create one
    anaconda_create_user() unless (get_var("USER_LOGIN") eq 'false' || get_var("INSTALL_NO_USER"));
    # Check username (and hence keyboard layout) if non-English
    if (get_var('LANGUAGE')) {
        assert_screen "anaconda_install_user_created";
    }
}

sub run {
    my $self = shift;
    # From F31 onwards (after Fedora-Rawhide-20190722.n.1), user and
    # root password spokes are moved to main hub, so we must do those
    # before we run the install.
    my $rootuserdone = 0;
    assert_screen ["anaconda_main_hub_begin_installation", "anaconda_install_root_password"], 300;
    if (match_has_tag "anaconda_install_root_password") {
        _do_root_and_user();
        $rootuserdone = 1;
    }
    # Begin installation
    # Sometimes, the 'slide in from the top' animation messes with
    # this - by the time we click the button isn't where it was any
    # more. So wait for screen to stop moving before we click.
    wait_still_screen 2;
    assert_and_click "anaconda_main_hub_begin_installation";

    # If we want to test identification we will do it
    # on several places in this procedure, such as
    # on this screen and also on password creation screens
    # etc.
    my $identification = get_var('IDENTIFICATION');
    my $branched = get_var('VERSION');
    if ($identification eq 'true' or $branched ne "Rawhide") {
        check_left_bar();
        check_prerelease();
        check_version();
    }

    unless ($rootuserdone) {
        _do_root_and_user();
        # With the slow typing - especially with SWITCHED_LAYOUT - we
        # may not complete user creation until anaconda reaches post-install,
        # which causes a 'Finish configuration' button
        if (check_screen "anaconda_install_finish_configuration", 5) {
            assert_and_click "anaconda_install_finish_configuration";
        }
    }

    # Wait for install to end. Give Rawhide a bit longer, in case
    # we're on a debug kernel, debug kernel installs are really slow.
    my $timeout = 1800;
    my $version = lc(get_var('VERSION'));
    if ($version eq "rawhide") {
        $timeout = 2400;
    }
    # workstation especially has an unfortunate habit of kicking in
    # the screensaver during install...
    my $interval = 60;
    while ($timeout > 0) {
        # move the mouse a bit
        mouse_set 100, 100;
        mouse_hide;
        last if (check_screen "anaconda_install_done", $interval);
        $timeout -= $interval;
    }
    assert_screen "anaconda_install_done";
    # wait for transition to complete so we don't click in the sidebar
    wait_still_screen 3;
    # if this is a live install, let's go ahead and quit the installer
    # in all cases, just to make sure quitting doesn't crash etc.
    assert_and_click "anaconda_install_done" if (get_var('LIVE'));
    # there are various things we might have to do at a console here
    # before we actually reboot. let's figure them all out first...
    my @actions;
    push (@actions, 'consoletty0') if (get_var("ARCH") eq "aarch64");
    push (@actions, 'abrt') if (get_var("ABRT") eq "system");
    push (@actions, 'rootpw') if (get_var("INSTALLER_NO_ROOT"));
    # memcheck test doesn't need to reboot at all. Rebooting from GUI
    # for lives is unreliable. And if we're already doing something
    # else at a console, we may as well reboot from there too
    push (@actions, 'reboot') if (!get_var("MEMCHECK") && (get_var("LIVE") || @actions));
    # our approach for taking all these actions doesn't work on VNC
    # installs, fortunately we don't need any of them in that case
    # yet, so for now let's just flush the list here if we're VNC
    @actions = () if (get_var("VNC_CLIENT"));
    # If we have no actions, let's just go ahead and reboot now,
    # unless this is memcheck
    unless (@actions) {
        unless (get_var("MEMCHECK")) {
            assert_and_click "anaconda_install_done";
        }
        return undef;
    }
    # OK, if we're here, we got actions, so head to a console. Switch
    # to console after liveinst sometimes takes a while, so 30 secs
    $self->root_console(timeout=>30);
    # this is something a couple of actions may need to know
    my $mount = "/mnt/sysimage";
    if (get_var("CANNED")) {
        # finding the actual host system root is fun for ostree...
        $mount = "/mnt/sysimage/ostree/deploy/fedora*/deploy/*.?";
    }
    if (grep {$_ eq 'consoletty0'} @actions) {
        # somehow, by this point, localized keyboard layout has been
        # loaded for this tty, so for French and Arabic at least we
        # need to load the 'us' layout again for the next command to
        # be typed correctly
        console_loadkeys_us;
        # https://bugzilla.redhat.com/show_bug.cgi?id=1661288 results
        # in boot messages going to serial console on aarch64, we need
        # them on tty0. We also need 'quiet' so we don't get kernel
        # messages, which screw up some needles
        assert_script_run 'sed -i -e "s,\(GRUB_CMDLINE_LINUX.*\)\",\1 console=tty0 quiet\",g" ' . $mount . '/etc/default/grub';
        # regenerate the bootloader config
        assert_script_run "chroot $mount grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg";
    }
    if (grep {$_ eq 'abrt'} @actions) {
         # Chroot in the newly installed system and switch on ABRT systemwide
         assert_script_run "chroot $mount abrt-auto-reporting 1";
    }
    if (grep {$_ eq 'rootpw'} @actions) {
        my $root_password = get_var("ROOT_PASSWORD") || "weakpassword";
        assert_script_run "echo 'root:$root_password' | chpasswd -R $mount";
    }
    type_string "reboot\n" if (grep {$_ eq 'reboot'} @actions);
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
