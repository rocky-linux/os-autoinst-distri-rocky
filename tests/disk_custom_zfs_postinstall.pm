use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that xfs is used on root partition
    assert_script_run "mount | grep 'on / type xfs'";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
