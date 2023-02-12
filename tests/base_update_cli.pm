use base "installedtest";
use strict;
use testapi;
use packagetest;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);
    # enable test repos and install test packages
    prepare_test_packages;
    # check rpm agrees they installed good
    verify_installed_packages;
    # update the fake python3-kickstart (should come from the real repo)
    # this can take a long time if we get unlucky with the metadata refresh
    assert_script_run 'dnf -y --disablerepo=openqa-testrepo* --disablerepo=updates-testing update python3-kickstart', 600;
    # check we got the updated version
    verify_updated_packages;
    # now remove python3-kickstart, and see if we can do a straight
    # install from the default repos
    assert_script_run 'dnf -y remove python3-kickstart';
    assert_script_run 'dnf -y --disablerepo=openqa-testrepo* --disablerepo=updates-testing install python3-kickstart', 120;
    assert_script_run 'rpm -V python3-kickstart';
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
