use base "anacondatest";
use strict;
use lockapi;
use testapi;
use utils;
use anaconda;

sub run {
    # This test tests that Anaconda is able to show help for particular Anaconda screens.
    # It opens various Anaconda panes, clicks on Help button, and checks that correct
    # Help content is shown for that pane.
    #
    # Although this test performs Anaconda routines and it only partly performs the installation,
    # therefore it is NOT to be considered an *installation test*.
    #
    # This tests should run after the _boot_to_anaconda test. Which should take us to Anaconda
    # main hub.
    # Now, we should be on Anaconda Main hub, but the hub differs for various
    # installation media. For each such media (ServerDVD, WS Live, KDE Live),
    # we create a tailored test plan.
    #
    # At first, we check for the main hub help.
    check_help_on_pane("main");

    # Create test plans
    my @testplan;
    # For LIVE KDE:
    if ((get_var('LIVE')) && (get_var('DESKTOP') eq "kde")) {
        @testplan = qw/keyboard_layout time_date install_destination network_host_name root_password create_user/;
    }
    # For LIVE Workstation
    elsif ((get_var('LIVE')) && (get_var('DESKTOP') eq "gnome")) {
        @testplan = qw/keyboard_layout install_destination time_date/;
    }
    # For Silverblue
    elsif (get_var('DESKTOP') eq "gnome") {
        @testplan = qw/keyboard_layout language_support install_destination time_date/;
    }
    # For ServerDVD
    else {
        @testplan = qw/keyboard_layout language_support time_date installation_source select_packages install_destination network_host_name root_password create_user/;
    }

    # Iterate over test plan and do the tests.
    foreach (@testplan) {
        check_help_on_pane($_);
    }

    # Now, we will start the installation.
    # on GNOME installs (Workstation Live and Silverblue) we don't
    # need to set a root password or create a user; on other flavors
    # we must
    unless (get_var("DESKTOP") eq "gnome" ) {
        assert_and_click "anaconda_main_hub_root_password";
        type_safely "weakrootpassword";
        send_key "tab";
        type_safely "weakrootpassword";
        assert_and_click "anaconda_spoke_done";
    }
    # Begin installation after waiting out animation
    wait_still_screen 5;
    wait_screen_change { assert_and_click "anaconda_main_hub_begin_installation"; };

    # Check the last Help screen
    check_help_on_pane("installation_progress");

    # As there is no need to proceed with the installation,
    # the test ends here and the VM will be destroyed
    # after some short time.

}

1;
