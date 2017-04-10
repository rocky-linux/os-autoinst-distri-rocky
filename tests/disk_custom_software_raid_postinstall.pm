use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that RAID is used
    validate_script_output "cat /proc/mdstat", sub { $_ =~ m/Personalities : \[raid1\]/ };
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
