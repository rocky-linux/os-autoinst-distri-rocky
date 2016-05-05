use base "basetest";
use strict;
use testapi;

sub run {
    # If KICKSTART is set, then the wait_time needs to consider the
    # install time. if UPGRADE, we have to wait for the entire upgrade
    my $wait_time = 300;
    $wait_time = 1800 if (get_var("KICKSTART"));
    $wait_time = 6000 if (get_var("UPGRADE"));

    # Wait for the login screen
    assert_screen "graphical_login", $wait_time;
    # handle the qemu display buffer sometimes showing the DM from the
    # *previous* boot - https://openqa.stg.fedoraproject.org/tests/17116
    wait_still_screen;
    assert_screen "graphical_login";
    # do user login unless USER_LOGIN is set to string 'false'
    unless (get_var("USER_LOGIN") eq "false") {
        if (get_var("DESKTOP") eq 'gnome') {
            # we have to hit enter to get the password dialog
            send_key "ret";
        }
        assert_screen "graphical_login_input";
        type_string get_var("USER_PASSWORD", "weakpassword");
        send_key "ret";

        # Handle initial-setup, for GNOME, unless START_AFTER_TEST
        # is set in which case it will have been done already
        if (get_var("DESKTOP") eq 'gnome' && !get_var("START_AFTER_TEST")) {
            for my $n (1..3) {
                # click 'Next' three times, moving the mouse to avoid
                # highlight problems, sleeping to give it time to get
                # to the next screen between clicks
                mouse_set(100, 100);
                wait_screen_change { assert_and_click "next_button", 60; };
            }
            # click 'Skip' one time
            mouse_set(100,100);
            wait_screen_change { assert_and_click "skip_button"; };
            send_key "ret";
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
