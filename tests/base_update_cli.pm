use base "installedtest";
use strict;
use testapi;
use packagetest;
use utils;

sub run {
    my $self = shift;

    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);

    # enable test repos and install test packages
    prepare_test_packages;

    # check rpm agrees they installed good
    verify_installed_packages;

    # update the fake acpica-tools (should come from the real repo)
    # this can take a long time if we get unlucky with the metadata refresh
    assert_script_run 'dnf -y --disablerepo=openqa-testrepo* update acpica-tools', 600;

    # check we got the updated version
    verify_updated_packages;

    # now remove acpica-tools, and see if we can do a straight
    # install from the default repos
    assert_script_run 'dnf -y remove acpica-tools';
    assert_script_run 'dnf -y --disablerepo=openqa-testrepo* install acpica-tools', 120;
    assert_script_run 'rpm -V acpica-tools';
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
