use base "installedtest";
use strict;
use testapi;
use utils;
use packagetest;
use cockpit;

sub run {
    my $self=shift;
    bypass_1691487;

    my $cockdate = "0";
    # Remove a package, disable repositories and enable test repositories, install the package
    # from that repository to make the system outdated and verify that that package was
    # correctly installed.
    prepare_test_packages;
    verify_installed_packages;

    # Start Cockpit
    start_cockpit(1);
    # Navigate to update screen
    select_cockpit_update();


    # If security updates are available, install them first,
    # so that we test the most buttons in one go.
    # After updates, ignore restart because we do not need
    # restarting the machine to continue. Also, we would have
    # to deal with much more complicated workflow.
    #
    if (check_screen('cockpit_updates_security_install',1)) {
       assert_and_click 'cockpit_updates_security_install';
       sleep 60; # wait until things are installed
       assert_and_click 'cockpit_updates_restart_ignore';
       wait_still_screen 2;
    }


    # Install the rest of the updates, or any updates
    # that have not been previously installed.
    assert_and_click 'cockpit_updates_all_install';
    my $run = 0;
    while ($run < 40) {
        # When Cockpit packages are also included in the updates
        # the user is forced to reconnect, i.e. to restart the Web Application
        # and relog for further interaction. We will check if reconnection is
        # needed and if so, we will restart Firefox and login again.
        #
        last if (check_screen("cockpit_updates_updated"));
        if (check_screen("cockpit_updates_reconnect", 1)) {
            quit_firefox;
            sleep 5;
            start_cockpit(1);
            select_cockpit_update();
            last;

        }
        # Ignore rebooting the system because we want to finish the test instead.
        elsif (check_screen('cockpit_updates_restart_ignore', 1)) {
            assert_and_click 'cockpit_updates_restart_ignore';
            last;
        }
        else {
            sleep 10;
            $run = $run + 1;
        }
    }
    # Check that the system is updated
    assert_screen 'cockpit_updates_updated';

    # Switch off Cockpit
    quit_firefox;

    # Wait a couple of seconds for the terminal to settle down, the command was
    # entered incorrectly which resulted in a failure.
    sleep 5;

    # Verify that the test package was updated correctly.
    verify_updated_packages;
}

sub test_flags {
    return { always_rollback => 1 };
}

1;

# vim: set sw=4 et:
