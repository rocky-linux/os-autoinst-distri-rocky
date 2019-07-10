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

    # Check that modularity works, that a particular module is available in the system, 
    # and display information about that module.
    assert_script_run('/root/test.py -m dwm -s 6.1 -a list');

    # Check that module can be enabled and disabled.
    assert_script_run('/root/test.py -m dwm -s 6.1 -a enable,disable -f hard');
    
    # Upload the modular log file.
    upload_logs '/root/modular.log', failok=>1;
}

1;

# vim: set sw=4 et:
