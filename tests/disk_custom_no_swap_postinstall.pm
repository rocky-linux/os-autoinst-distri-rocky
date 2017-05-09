use base "installedtest";
use strict;
use testapi;

sub run {
    assert_screen "root_console";
    # check that swap is not used, check that "swapon --show has empty input"
    assert_script_run '[[ ! $(swapon --show) ]]';
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
