use base "installedtest";
use strict;
use testapi;
use utils;

sub reboot_and_login {
    # This subroutine reboots the host, waits out the boot process and logs in.
    my $reboot_time = shift;
    script_run "systemctl reboot";
    boot_to_login_screen(timeout => $reboot_time);
    console_login(user => "root", password => get_var("ROOT_PASSWORD"));
    sleep 2;
}

sub run {
    my $self = shift;
    my $reboot_time = 300;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);

    # Install wget as rpm-ostree overlay. Let's have timeout defined
    # quite generously, because it loads the package DBs.
    assert_script_run "rpm-ostree install wget", timeout => 300;
    # Reboot the machine to boot into the overlayed tree.
    reboot_and_login "300";

    # Check that wget rpm is installed
    assert_script_run "rpm -q wget";
    # And that it works
    assert_script_run "wget --version";

    # Then install the httpd package.
    assert_script_run "rpm-ostree install httpd", timeout => 300;

    # Reboot the machine to boot into the overlayed tree.
    reboot_and_login "300";

    # Check for new as well as old overlays
    assert_script_run "rpm -q wget";
    assert_script_run "rpm -q httpd";
    assert_script_run "rpm -q apr";

    # Start the httpd.service and check for its status
    assert_script_run "systemctl start httpd";
    assert_script_run "systemctl is-active httpd";

    # Check for the functional test page
    assert_script_run "curl -o page.html http://localhost";
    assert_script_run "grep 'Fedora Project' page.html";

    # Enable the httpd service
    assert_script_run "systemctl enable httpd";

    # Reboot the computer to boot check if the service has been enabled and starts
    # automatically.
    reboot_and_login "300";

    # See if httpd is started
    assert_script_run "systemctl is-active httpd";

    # Uninstall wget and httpd again.
    assert_script_run "rpm-ostree uninstall wget httpd", timeout => 300;

    # Reboot to see the changed tree
    reboot_and_login "300";

    # Check if wget and httpd were removed and no longer can be used.
    assert_script_run "! rpm -q wget";
    assert_script_run "! rpm -q httpd";
    assert_script_run "! wget --version";
    assert_script_run "! systemctl is-active httpd";

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
