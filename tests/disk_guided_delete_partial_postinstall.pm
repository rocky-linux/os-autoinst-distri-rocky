use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # mount second partition and check that it's intact
    assert_script_run 'mount /dev/vda2 /mnt';
    validate_script_output 'cat /mnt/testfile', sub { $_ =~ m/Oh, hi Mark/ };
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
