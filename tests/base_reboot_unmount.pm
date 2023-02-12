use base "installedtest";
use strict;
use testapi;
use utils;


sub test_routine {
    # Save the result of the error tracking grep operation on journalctl output.
    script_run 'journalctl -b | grep -E "dirty bit|data may be corrupt|recovery|unmounted|recovering" > errors.txt';
    # Count the number of errors.
    my $errors_count = script_run "cat errors.txt | wc -l";
    # Die, if errors have been found.
    if ($errors_count != 0) {
        die "Unmount errors have been found in journalctl.";
    }

}

sub run {
    my $self = shift;
    # switch to TTY3 for both graphical and console tests
    $self->root_console(tty => 3);
    # Run test for the first time
    test_routine();
    # Reboot the system.
    type_safely "reboot\n";
    # This time, we will need to login manually.
    boot_to_login_screen;
    $self->root_console(tty => 3);

    # Run the tests for the second time.
    test_routine();
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
