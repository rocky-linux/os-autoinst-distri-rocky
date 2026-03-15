use base "anacondatest";
use strict;
use testapi;
use utils;
use anaconda;


# this enables you to send a command and some post-command wait time
# in one step and also distinguishes between serial or other consoles
# and handles the wait times differently.
sub console_type_wait {
    my ($string, $wait) = @_;
    $wait ||= 5;
    type_string $string;
    if (testapi::is_serial_terminal) {
        sleep $wait;
    }
    else {
        wait_still_screen $wait;
    }
}

sub run {
    my $self = shift;

    # First, preset the environment according to the chosen console.
    if (get_var("SERIAL_CONSOLE")) {
        select_console('virtio-console1');
        unless (testapi::is_serial_terminal) {
            die "The test does not run on a serial console when it should.";
        }
    }
    else {
        assert_screen "anaconda_main_hub_text";
        # IMHO it's better to use sleeps than to have needle for every text screen
        wait_still_screen 5;
    }

    # prepare for different number of spokes (e. g. as in Atomic DVD)
    my %spoke_number = (
        "language" => 1,
        "timezone" => 2,
        "source" => 3,
        "swselection" => 4,
        "destination" => 5,
        "kdump" => 6,
        "network" => 7,
        "rootpwd" => 8,
        "user" => 9
    );

    # The error message that we are going to check for in the text installation
    # must be different for serial console or other terminal emulator.
    my $error = "";
    if (testapi::is_serial_terminal) {
        $error = "unknown error has occured";
    }
    else {
        $error = "anaconda_text_error";
    }

    if (get_var("DISTRI") eq "rocky") {
        # Activate Network
        run_with_error_check(sub { console_type_wait($spoke_number{"network"} . "\n") }, $error);
        console_type_wait("2\n");    # Configure device
        console_type_wait("7\n");    # Connect automatically after reboot
        console_type_wait("8\n");    # Apply configuration in installer
        console_type_wait("c\n");    # Continue
        sleep 10;
        console_type_wait("r\n");    # Refresh
        console_type_wait("c\n");    # Continue

        # Software Selection
        run_with_error_check(sub { console_type_wait($spoke_number{"swselection"} . "\n") }, $error);
        console_type_wait("2\n");    # Server
        console_type_wait("c\n");    # Continue
        console_type_wait("c\n");    # Continue
        sleep 10;
        console_type_wait("r\n");    # Refresh
    }

    # Set timezone
    run_with_error_check(sub { console_type_wait($spoke_number{"timezone"} . "\n") }, $error);
    console_type_wait("1\n");    # Set timezone
    console_type_wait("1\n");    # Europe
    console_type_wait("37\n", 7);    # Prague

    # Select disk
    run_with_error_check(sub { console_type_wait($spoke_number{"destination"} . "\n") }, $error);
    console_type_wait("c\n");    # first disk selected, continue
    console_type_wait("c\n");    # use all space selected, continue
    console_type_wait("c\n", 7);    # LVM selected, continue

    # Set root password
    my $rootpwd = get_var("ROOT_PASSWORD", "weakpassword");
    run_with_error_check(sub { console_type_wait($spoke_number{"rootpwd"} . "\n") }, $error);
    console_type_wait("$rootpwd\n");
    console_type_wait("$rootpwd\n");

    # Create user
    my $userpwd = get_var("USER_PASSWORD", "weakpassword");
    my $username = get_var("USER_LOGIN", "test");
    run_with_error_check(sub { console_type_wait($spoke_number{"user"} . "\n") }, $error);
    console_type_wait("1\n");    # create new
    console_type_wait("3\n");    # set username
    console_type_wait("$username\n");
    console_type_wait("5\n");    # set password
    console_type_wait("$userpwd\n");
    console_type_wait("$userpwd\n");
    console_type_wait("6\n");    # make him an administrator
    console_type_wait("c\n", 7);

    my $counter = 0;
    if (testapi::is_serial_terminal) {
        while (wait_serial("[!]", timeout => 5, quiet => 1)) {
            if ($counter > 10) {
                die "There are unfinished spokes in Anaconda";
            }
            sleep 10;
            $counter++;
            console_type_wait("r\n");    # refresh
        }
    }
    else {
        while (check_screen "anaconda_main_hub_text_unfinished", 2) {
            if ($counter > 10) {
                die "There are unfinished spokes in Anaconda";
            }
            sleep 10;
            $counter++;
            console_type_wait("r\n");    # refresh
        }
    }

    # begin installation
    console_type_wait("b\n");

    # When simulated crash is planned, then proceed with the crash routines and finish,
    # otherwise proceed normally and do
    if (get_var("CRASH_REPORT")) {
        crash_anaconda_text;
        report_bug_text;
        return;
    }

    # Wait for install to end. Give Rawhide a bit longer, in case
    # we're on a debug kernel, debug kernel installs are really slow.
    my $timeout = 1800;
    if (lc(get_var('VERSION')) eq "rawhide" || lc(get_var('DISTRI')) eq "rocky") {
        $timeout = 4800;
    }

    if (testapi::is_serial_terminal) {
        wait_serial("Installation complete", timeout => $timeout);
        if (get_var("SERIAL_CONSOLE") && get_var("OFW")) {
            # for some reason the check for a prompt times out here, even
            # though '# ' is clearly in the terminal log; hack it out
            my $origprompt = $testapi::distri->{serial_term_prompt};
            $testapi::distri->{serial_term_prompt} = '';
            $self->root_console();
            # we need to force the system to load a console on both hvc1
            # and hvc2 for ppc64 serial console post-install tests
            assert_script_run 'chroot /mnt/sysimage systemctl enable serial-getty@hvc1';
            assert_script_run 'chroot /mnt/sysimage systemctl enable serial-getty@hvc2';
            $testapi::distri->{serial_term_prompt} = $origprompt;
            # back to anaconda ui
            select_console("virtio-console1");
        }
    }
    else {
        assert_screen "anaconda_install_text_done", $timeout;
    }
    console_type_wait("\n");
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
