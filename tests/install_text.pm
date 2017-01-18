use base "anacondatest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    assert_screen "anaconda_main_hub_text";
    # IMHO it's better to use sleeps than to have needle for every text screen
    wait_still_screen 5;

    # prepare for different number of spokes (e. g. as in Atomic DVD)
    my %spoke_number = (
        "language" => 1,
        "timezone" => 2,
        "source" => 3,
        "swselection" => 4,
        "destination" => 5,
        "network" => 6,
        "rootpwd" => 7,
        "user" => 8
    );

    # Set timezone
    run_with_error_check(sub {type_string $spoke_number{"timezone"} . "\n"}, "anaconda_text_error");
    wait_still_screen 5;
    type_string "1\n"; # Set timezone
    wait_still_screen 5;
    type_string "1\n"; # Europe
    wait_still_screen 5;
    type_string "37\n"; # Prague
    wait_still_screen 7;

    # Select disk
    run_with_error_check(sub {type_string $spoke_number{"destination"} . "\n"}, "anaconda_text_error");
    wait_still_screen 5;
    type_string "c\n"; # first disk selected, continue
    wait_still_screen 5;
    type_string "c\n"; # use all space selected, continue
    wait_still_screen 5;
    type_string "c\n"; # LVM selected, continue
    wait_still_screen 7;

    # Set root password
    run_with_error_check(sub {type_string $spoke_number{"rootpwd"} . "\n"}, "anaconda_text_error");
    wait_still_screen 5;
    type_string get_var("ROOT_PASSWORD", "weakpassword");
    send_key "ret";
    wait_still_screen 5;
    type_string get_var("ROOT_PASSWORD", "weakpassword");
    send_key "ret";
    wait_still_screen 7;

    # Create user
    run_with_error_check(sub {type_string $spoke_number{"user"} . "\n"}, "anaconda_text_error");
    wait_still_screen 5;
    type_string "1\n"; # create new
    wait_still_screen 5;
    type_string "3\n"; # set username
    wait_still_screen 5;
    type_string get_var("USER_LOGIN", "test");
    send_key "ret";
    wait_still_screen 5;
    # typing "4\n" on abrt screen causes system to reboot, so be careful
    run_with_error_check(sub {type_string "4\n"}, "anaconda_text_error"); # use password
    wait_still_screen 5;
    type_string "5\n"; # set password
    wait_still_screen 5;
    type_string get_var("USER_PASSWORD", "weakpassword");
    send_key "ret";
    wait_still_screen 5;
    type_string get_var("USER_PASSWORD", "weakpassword");
    send_key "ret";
    wait_still_screen 5;
    type_string "6\n"; # make him an administrator
    wait_still_screen 5;
    type_string "c\n";
    wait_still_screen 7;

    my $counter = 0;
    while (check_screen "anaconda_main_hub_text_unfinished", 2) {
        if ($counter > 10) {
            die "There are unfinished spokes in Anaconda";
        }
        sleep 10;
        $counter++;
        type_string "r\n"; # refresh
    }

    # begin installation
    type_string "b\n";

    # Wait for install to end. Give Rawhide a bit longer, in case
    # we're on a debug kernel, debug kernel installs are really slow.
    my $timeout = 1800;
    if (lc(get_var('VERSION')) eq "rawhide") {
        $timeout = 2400;
    }
    assert_screen "anaconda_install_text_done", $timeout;
    type_string "\n";
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
