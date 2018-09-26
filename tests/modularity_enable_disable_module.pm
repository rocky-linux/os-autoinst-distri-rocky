use base "installedtest";
use strict;
use testapi;
use utils;
sub run {
    my $self=shift;
    my $hook_run = 0;
    # switch to tty and login as root
    $self->root_console(tty=>3);

    # Download the testing script
    download_modularity_tests();

    # Check that modularity works and that a particular module is available in the system.
    assert_script_run('/root/test.py -m dwm -s 6.0 -a list');

    # Check that module can be enabled and disabled.
    assert_script_run('/root/test.py -m dwm -s 6.0 -a enable,disable -f hard');
}

1;

# vim: set sw=4 et:
