use base "anacondatest";
use strict;
use testapi;
use utils;


sub enable_abrt_and_quit {
     # Chroot in the newly installed system
     script_run "chroot /mnt/sysimage/";
     # Switch on ABRT systemwide
     script_run "abrt-auto-reporting 1";
     # Exit the chroot
     type_string "exit\n";
     # Reboot the installed machine
     type_string "reboot\n";

}

sub run {
    my $self = shift;
    # Begin installation
    assert_screen "anaconda_main_hub_begin_installation", 300;
    # Sometimes, the 'slide in from the top' animation messes with
    # this - by the time we click the button isn't where it was any
    # more. So wait for screen to stop moving before we click.
    wait_still_screen 2;
    assert_and_click "anaconda_main_hub_begin_installation";

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
        assert_and_click "anaconda_spoke_done";
    }

    # Wait out animation
    sleep 8;
    # Set user details, unless the test is configured not to create one
    anaconda_create_user() unless (get_var("USER_LOGIN") eq 'false' || get_var("INSTALL_NO_USER"));

    # Check username (and hence keyboard layout) if non-English
    if (get_var('LANGUAGE')) {
        assert_screen "anaconda_install_user_created";
    }

    # With the slow typing - especially with SWITCHED_LAYOUT - we
    # may not complete user creation until anaconda reaches post-install,
    # which causes a 'Finish configuration' button
    if (check_screen "anaconda_install_finish_configuration", 5) {
        assert_and_click "anaconda_install_finish_configuration";
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
    # on aarch64, the default console is set by kernel config to the
    # serial console. we don't want this, it messes up decryption
    # (as plymouth will expect the passphrase on the serial console,
    # not the virtual console). Let's go fix this up now.
    if (get_var("ARCH") eq "aarch64") {
        $self->root_console();
        # somehow, by this point, localized keyboard layout has been
        # loaded for this tty, so for French and Arabic at least we
        # need to load the 'us' layout again for the next command to
        # be typed correctly
        console_loadkeys_us;
        # stick 'console=tty0' on the end of GRUB_CMDLINE_LINUX in
        # the grub defaults file, and 'quiet' so we don't get kernel
        # messages, which screws up some needles. RHBZ#1661288
        assert_script_run 'sed -i -e "s,\(GRUB_CMDLINE_LINUX.*\)\",\1 console=tty0 quiet\",g" /mnt/sysimage/etc/default/grub';
        # regenerate the bootloader config
        assert_script_run "chroot /mnt/sysimage grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg";
        # let's just reboot from here, seems simplest
        type_string "reboot\n" unless (get_var("MEMCHECK"));
        return;
    }
    # for the memory check test, we *don't* want to leave
    unless (get_var("MEMCHECK")) {
    # If the variable for system-wide ABRT is set to system, switch 
    # the system usage of ABRT on, before rebooting the installation, 
    # so that the VM can start with the new settings.
        if (get_var("ABRT") eq "system" && !get_var("LIVE"))  {
            $self->root_console(timeout=>30);
            enable_abrt_and_quit();
        }
        elsif ((get_var("DESKTOP") eq "gnome") && ($version eq "30" || $version eq "rawhide") && get_var("ADVISORY") ne "FEDORA-2019-ac2a21ff07") {
            # FIXME workaround for
            # https://bugzilla.redhat.com/show_bug.cgi?id=1699099
            # remove when fixed
            $self->root_console(timeout=>30);
            console_loadkeys_us;
            script_run 'sed -i -e "s,SELINUX=enforcing,SELINUX=permissive,g" /mnt/sysimage/etc/selinux/config';
            type_string "reboot\n" unless (get_var("LIVE"));
        }
        else {
            assert_and_click "anaconda_install_done";
        }
        
        if (get_var('LIVE')) {
            # reboot from a console, it's more reliable than the desktop
            # runners. As of 2018-10 switching to console after liveinst
            # seems to take a long time, so use a longer timeout here
            $self->root_console(timeout=>30);
            # if we didn't set a root password during install, set it
            # now...this is kinda icky, but I don't see a great option
            if (get_var("INSTALLER_NO_ROOT")) {
                # https://bugzilla.redhat.com/show_bug.cgi?id=1553957
                assert_script_run "setenforce 0";
                assert_script_run "echo 'root:$root_password' | chpasswd -R /mnt/sysimage";
            }
            if (get_var("ABRT") eq "system") {
                enable_abrt_and_quit();
            }
            else {
                type_string "reboot\n";
            }
        }
    }
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
