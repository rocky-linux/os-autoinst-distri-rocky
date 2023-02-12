use base "installedtest";
use strict;
use testapi;
use utils;
sub run {
    my $self = shift;
    # switch to tty and login as root
    $self->root_console(tty => 3);

    # Download the testing script
    download_modularity_tests('whitelist');

    # Test if modules have default stream and profile defined.
    assert_script_run('/root/test.py -a checkdefaults -w whitelist');

    # Upload modular logs
    upload_logs '/root/modular.log', failok => 1;
}

1;

# vim: set sw=4 et:
