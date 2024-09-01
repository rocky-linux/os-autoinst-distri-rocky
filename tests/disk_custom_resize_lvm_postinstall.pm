use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that there is a root partition and that it has
    # the correct size -> 11.5G
    script_run "lsblk";
    assert_script_run "lsblk | grep root | grep '11.5G'";
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
