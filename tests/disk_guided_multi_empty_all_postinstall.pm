use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";

    # when two disks are selected in installation, LVM is used
    validate_script_output "pvdisplay", sub { $_ =~ m/\/dev\/vda/ && $_ =~ m/\/dev\/vdb/ };
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
