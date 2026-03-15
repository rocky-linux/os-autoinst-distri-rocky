use base "installedtest";
use strict;
use testapi;
use anaconda;
use utils;

sub run {
    my $self = shift;
    my $password = get_var("USER_PASSWORD", "weakpassword");
    my $version = get_var("VERSION");
    # If KICKSTART is set, then the wait_time needs to consider the
    # install time. if UPGRADE, we have to wait for the entire upgrade
    # unless ENCRYPT_PASSWORD is set (in which case the postinstall
    # test does the waiting)
    my $wait_time = 300;
    $wait_time = 1800 if (get_var("KICKSTART"));
    $wait_time = 6000 if (get_var("UPGRADE") && !get_var("ENCRYPT_PASSWORD"));

    # handle bootloader, if requested
    if (get_var("GRUB_POSTINSTALL")) {
        do_bootloader(postinstall => 1, params => get_var("GRUB_POSTINSTALL"), timeout => $wait_time);
        $wait_time = 300;
    }

    # Handle pre-login initial setup if we're doing INSTALL_NO_USER
    if (get_var("INSTALL_NO_USER") && !get_var("_SETUP_DONE")) {
        if (get_var("DESKTOP") eq 'gnome') {
            gnome_initial_setup(prelogin => 1, timeout => $wait_time);
        }
        else {
            anaconda_create_user(timeout => $wait_time);
            # wait out animation
            wait_still_screen 3;
            assert_and_click "initialsetup_finish_configuration";
            set_var("_SETUP_DONE", 1);
        }
        $wait_time = 300;
    }
    # Wait for the login screen, unless we're doing a GNOME no user
    # install, which transitions straight from g-i-s to logged-in
    # desktop
    unless (get_var("DESKTOP") eq 'gnome' && get_var("INSTALL_NO_USER")) {
        unless (get_var("HDD_1") && !(get_var("PARTITIONING") eq "custom_resize_lvm")) {
            # in 9.0, license screens are not shown by default
         # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/9.0_release_notes/index#enhancement_installer-and-image-creation
            unless (get_version_major() > 8) {
                # for Rocky Linux here happens to be a license acceptance screen
                # the initial appearance can sometimes take really long
                assert_screen "gdm_initial_setup_license", 120;
                assert_and_click "gdm_initial_setup_license";
                # Make sure the card has fully lifted until clicking on the buttons
                wait_still_screen 5, 30;
                assert_and_click "gdm_initial_setup_licence_accept";
                assert_and_click "gdm_spoke_done";
                # As well as coming back
                wait_still_screen 5, 30;
                assert_screen "gdm_initial_setup_license_accepted";
                assert_and_click "gdm_initial_setup_spoke_forward";
            }
        }

        boot_to_login_screen(timeout => $wait_time);
        # if USER_LOGIN is set to string 'false', we're done here
        return if (get_var("USER_LOGIN") eq "false");

        # GDM 3.24.1 dumps a cursor in the middle of the screen here...
        mouse_hide;
        if (get_var("DESKTOP") eq 'gnome') {
            if (get_version_major() > 8) {
                send_key_until_needlematch("graphical_login_test_user_highlighted", "tab", 5);
                assert_screen "graphical_login_test_user_highlighted";
            }
            # we have to hit enter to get the password dialog, and it
            # doesn't always work for some reason so just try it three
            # times
            send_key_until_needlematch("graphical_login_input", "ret", 3, 5);
        }
        assert_screen "graphical_login_input";
        # seems like we often double-type on aarch64 if we start right
        # away
        wait_still_screen 5;
        if (get_var("SWITCHED_LAYOUT")) {
            # see _do_install_and_reboot; when layout is switched
            # user password is doubled to contain both US and native
            # chars
            desktop_switch_layout 'ascii';
            type_very_safely $password;
            desktop_switch_layout 'native';
            type_very_safely $password;
        }
        else {
            type_very_safely $password;
        }
        send_key "ret";
    }

    # Welcome tour is here...

    # For GNOME, handle initial-setup or welcome tour, unless START_AFTER_TEST
    # is set in which case it will have been done already. Always
    # do it if ADVISORY_OR_TASK is set, as for the update testing flow,
    # START_AFTER_TEST is set but a no-op and this hasn't happened
    if (get_var("DESKTOP") eq 'gnome' && (get_var("ADVISORY_OR_TASK") || !get_var("START_AFTER_TEST"))) {
        # as this test gets loaded twice on the ADVISORY_OR_TASK flow, and
        # we might be on the INSTALL_NO_USER flow, check whether
        # this happened already
        my $version_major = get_version_major();
        if ($version_major < 9) {
            # before GNOME 40 we get a per-user version of
            # gnome-initial-setup here...
            gnome_initial_setup() unless (get_var("_SETUP_DONE"));
        }
        else {
            # ...from GNOME 40 on, we just get a "Welcome" tour
            handle_welcome_screen unless (get_var("_WELCOME_DONE"));
        }
    }
    # FIXME: Figure out why this was added. seems to be handled above. inclusion
    # causes soft-fail.
    #if (get_version_major() > 8) {
    #    handle_welcome_screen unless (get_var("_WELCOME_DONE"));
    #}
    if (get_var("DESKTOP") eq 'gnome' && get_var("INSTALL_NO_USER")) {
        # handle welcome screen if we didn't do it above (holy flow
        # control, Batman!)
        handle_welcome_screen unless (get_var("_WELCOME_DONE"));
        # if this was an image deployment, we also need to create
        # root user now, for subsequent tests to work
        if (get_var("IMAGE_DEPLOY")) {
            select_console "tty3-console";
            console_login(user => get_var("USER_LOGIN", "test"), password => get_var("USER_PASSWORD", "weakpassword"));
            type_string "sudo su\n";
            type_string "$password\n";
            my $root_password = get_var("ROOT_PASSWORD") || "weakpassword";
            assert_script_run "echo 'root:$root_password' | chpasswd";
            desktop_vt;
        }
    }

    # Move the mouse somewhere it won't highlight the match areas
    mouse_set(300, 800);
    # KDE can take ages to start up
    check_desktop(timeout => 120);
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
