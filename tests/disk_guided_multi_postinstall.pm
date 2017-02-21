use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that second disk is intact
    if (get_var('OFW')) {
        # on PowerPC, installation disk is second disk (vdb)
        # so need to check vda
        assert_script_run 'mount /dev/vda1 /mnt';
    } else {
        assert_script_run 'mount /dev/vdb1 /mnt';
    }
    validate_script_output 'cat /mnt/testfile', sub { $_ =~ m/Hello, world!/ };
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
