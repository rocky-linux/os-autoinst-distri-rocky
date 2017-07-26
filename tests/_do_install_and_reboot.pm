use base "anacondatest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # Begin installation
    # Deal with RHBZ #1444225: if INSTALLATION DESTINATION is showing
    # incomplete (which it never should at this point), take a quick
    # trip through it to fix it
    foreach my $i (1..150) {
        last if (check_screen "anaconda_main_hub_begin_installation", 1);
        if (check_screen "anaconda_main_hub_install_destination_warning", 1) {
            record_soft_failure "RHBZ #1444225 (INSTALLATION DESTINATION bug)";
            assert_and_click "anaconda_main_hub_install_destination";
            wait_still_screen 2;
            assert_and_click "anaconda_spoke_done";
            # if this is an encrypted install, re-confirm passphrase
            assert_and_click "anaconda_install_destination_save_passphrase" if (get_var("ENCRYPT_PASSWORD"));
        }
    }
    # Sometimes, the 'slide in from the top' animation messes with
    # this - by the time we click the button isn't where it was any
    # more. So wait for screen to stop moving before we click.
    wait_still_screen 2;
    assert_and_click "anaconda_main_hub_begin_installation";

    # Set root password
    my $root_password = get_var("ROOT_PASSWORD") || "weakpassword";
    assert_and_click "anaconda_install_root_password";
    assert_screen "anaconda_install_root_password_screen";
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

    # Wait out animation
    sleep 3;
    # Set user details
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
    if (lc(get_var('VERSION')) eq "rawhide") {
        $timeout = 2400;
    }
    assert_screen "anaconda_install_done", $timeout;
    # wait for transition to complete so we don't click in the sidebar
    wait_still_screen 3;
    # for the memory check test, we *don't* want to leave
    unless (get_var("MEMCHECK")) {
        assert_and_click "anaconda_install_done";
        if (get_var('LIVE')) {
            # reboot from a console, it's more reliable than the desktop
            # runners
            $self->root_console;
            type_string "reboot\n";
        }
    }
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
