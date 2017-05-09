use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that ext3 is used on root partition
    assert_script_run "mount | grep 'on / type ext3'";
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
