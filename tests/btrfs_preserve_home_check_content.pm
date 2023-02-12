use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);
    # The pre-created image has a special file left in the home
    # directory. This checks that the file has been left there
    # correctly after system reinstall.
    assert_script_run "ls /home/home_preserved";
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
