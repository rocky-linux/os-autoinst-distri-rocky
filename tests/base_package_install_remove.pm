use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);

    # This test case tests that packages can be correctly installed and removed.
    # We will test by installing two packages - ftp and mc.
    #
    # Install the FTP package.
    assert_script_run("dnf install -y ftp", timeout => 240);
    # Check the main packages are installed.
    # Confirm that dnf lists the package
    assert_script_run("dnf list ftp");
    # Confirm that RPM lists the packages
    assert_script_run("rpm -q ftp");
    # Verify the installations using rpm --verify
    assert_script_run("rpm --verify ftp");

    # Install the MC package.
    assert_script_run("dnf install -y mc", timeout => 240);
    # Check the main packages are installed.
    # Confirm that dnf lists the package
    assert_script_run("dnf list mc");
    # Confirm that RPM lists the packages
    assert_script_run("rpm -q mc");
    # Verify the installations using rpm --verify
    assert_script_run("rpm --verify mc");

    # Now we will uninstall the packages again and we will check that they have been uninstalled.
    # We will not check that all of the dependencies have been uninstalled, too, because the
    # dependencies might have been on the system already to satisfy some other packages' needs,
    # which we believe is the normal user approach.
    #
    # Uninstall the packages.
    assert_script_run("dnf remove -y ftp mc");
    # Reports by the DNF
    assert_script_run("!dnf list ftp");
    assert_script_run("!dnf list mc");
    # Reports by the RPM
    assert_script_run("!rpm -q ftp");
    assert_script_run("!rpm -q mc");

}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
