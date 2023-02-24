use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);

    # Use ssh to log into this machine to see its status.
    type_string "ssh test\@localhost\n";
    sleep 2;
    # It is very probable that this is the first time that anybody
    # wants to ssh in. We need to accept the authentication.
    type_string "yes\n";
    sleep 1;
    # Type the user password for this connection and hopefully log in.
    my $pwd = get_var("USER_PASSWORD") // "weakpassword";
    type_string "$pwd\n";
    sleep 2;

    # Check that the output is correct as expected.
    assert_screen "iot_greenboot_passed";

    # Logout from the ssh connection.
    type_string "exit\n";
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
