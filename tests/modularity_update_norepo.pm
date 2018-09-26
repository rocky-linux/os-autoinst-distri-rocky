use base "installedtest";
use strict;
use testapi;
use utils;
sub run {
    my $self=shift;
    # switch to tty and login as root
    $self->root_console(tty=>3);

    # Download the testing script
    download_modularity_tests();

    # Update the system
    assert_script_run('dnf update -y');

    # Enable and install the nodejs module, stream 8.
    assert_script_run('/root/test.py -m nodejs -s 8 -a enable,install -f hard');

    # Update the system without modular repos.
    assert_script_run('dnf update --disablerepo=\*modular -y');

    # Check that the same version is listed in the installed modules.
    assert_script_run('/root/test.py -m nodejs -s 8 -a checkinstall -f hard');
}

1;

# vim: set sw=4 et:
