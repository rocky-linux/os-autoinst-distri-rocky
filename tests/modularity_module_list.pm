use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self=shift;
    # switch to tty and login as root
    $self->root_console(tty=>3);

    # The test case will check that dnf has modular functions and that
    # it is possible to invoke modular commands to work with modularity.
    # It does not check the content of the further listed lists for any
    # particular packages, modules or streams.

    # Check that modularity works and dnf can list the modules.
    assert_script_run('dnf module list');

    # Check that modularity works and dnf can list the modules
    # with the -all option.
    assert_script_run('dnf module list --all');

    # Check that dnf lists the enabled modules.
    assert_script_run('dnf module list --enabled');

    # Check that dnf lists the disabled modules.
    assert_script_run('dnf module list --disabled');

    # Check that dnf lists the installed modules.
    assert_script_run('dnf module list --installed');
}


1;

# vim: set sw=4 et:
