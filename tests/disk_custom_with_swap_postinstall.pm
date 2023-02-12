use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # this is basically asserting that if we list all swaps and grep
    # out any zram ones, we still have one at prio -2, which should
    # be the disk-based one
    assert_script_run 'swapon --show | grep -v zram | grep "\-2"';
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
