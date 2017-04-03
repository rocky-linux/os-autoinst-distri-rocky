use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # If KICKSTART is set, then the wait_time needs to consider the
    # install time. if UPGRADE, we have to wait for the entire upgrade
    # unless ENCRYPT_PASSWORD is set (in which case the postinstall
    # test does the waiting)
    my $wait_time = 300;
    $wait_time = 1800 if (get_var("KICKSTART"));
    $wait_time = 6000 if (get_var("UPGRADE") && !get_var("ENCRYPT_PASSWORD"));

    # Handle pre-login initial setup if we're doing INSTALL_NO_USER
    if (get_var("INSTALL_NO_USER") && !get_var("_setup_done")) {
        if (get_var("DESKTOP") eq 'gnome') {
            gnome_initial_setup(prelogin=>1, timeout=>$wait_time);
        }
        else {
            anaconda_create_user(timeout=>$wait_time);
            assert_and_click "initialsetup_finish_configuration";
            set_var("_setup_done", 1);
        }
        $wait_time = 300;
    }
    # Wait for the login screen
    boot_to_login_screen(timeout => $wait_time);
    # do user login unless USER_LOGIN is set to string 'false'
    unless (get_var("USER_LOGIN") eq "false") {
        if (get_var("DESKTOP") eq 'gnome') {
            # we have to hit enter to get the password dialog
            send_key "ret";
        }
        assert_screen "graphical_login_input";
        my $password = get_var("USER_PASSWORD", "weakpassword");
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

        # Handle initial-setup, for GNOME, unless START_AFTER_TEST
        # is set in which case it will have been done already. Always
        # do it if ADVISORY is set, as for the update testing flow,
        # START_AFTER_TEST is set but a no-op and this hasn't happened
        if (get_var("DESKTOP") eq 'gnome' && (get_var("ADVISORY") || !get_var("START_AFTER_TEST"))) {
            # as this test gets loaded twice on the ADVISORY flow, and
            # we might be on the INSTALL_NO_USER flow, check whether
            # this happened already
            unless (get_var("_setup_done")) {
                gnome_initial_setup();
            }
        }
        if (get_var("DESKTOP") eq 'gnome' && get_var("INSTALL_NO_USER")) {
            # wait for the stupid 'help' screen to show and kill it
            assert_screen "getting_started";
            send_key "alt-f4";
            wait_still_screen 5;
        }

        # Move the mouse somewhere it won't highlight the match areas
        mouse_set(300, 200);
        # KDE can take ages to start up
        assert_screen "graphical_desktop_clean", 120;
    }
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1, milestone => 1 };
}

1;

# vim: set sw=4 et:
