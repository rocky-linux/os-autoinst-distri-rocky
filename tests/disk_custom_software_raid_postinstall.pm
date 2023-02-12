use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    unless (check_screen "root_console", 0) {
        $self->root_console(tty => 4);
    }
    assert_screen "root_console";
    # check that RAID is used
    assert_script_run "cat /proc/mdstat | grep 'Personalities : \\\[raid1\\\]'";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
