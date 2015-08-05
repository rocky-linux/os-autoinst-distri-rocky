use base "basetest";
use strict;
use testapi;

sub run {
    # If KICKSTART is set, then the wait_time needs to
    #  consider the install time
    my $wait_time = get_var("KICKSTART") ? 1800 : 300;

    # Wait for the login screen
    assert_screen "graphical_login", $wait_time;

    if (get_var("USER_LOGIN") && get_var("USER_PASSWORD")) {
        send_key "ret";
        type_string get_var("USER_PASSWORD");
        send_key "ret";
        # Move the mouse somewhere it won't highlight the match areas
        mouse_set(300, 200);
        assert_screen "graphical_desktop_clean", 30;
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
