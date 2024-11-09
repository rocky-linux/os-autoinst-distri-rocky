use base "installedtest";
use strict;
use testapi;
use utils;

# This script will download the test data for evince, start the application,
# and set a milestone as a starting point for the other Evince tests.
#

sub check_and_install_git {
    # Let's see if Git is installed and install it, if it isn't.
    unless (get_var("CANNED")) {
        if (script_run("rpm -q git")) {
            assert_script_run("dnf -y install git", 180);
        }
    }
}


sub download_testdata {
    # Navigate to the test's home directory
    assert_script_run("cd /home/test/");
    # Clone the test repository
    assert_script_run("git clone https://pagure.io/fedora-qa/openqa_testdata.git");
    # Change ownership and attributes
    assert_script_run("chown -R test:test openqa_testdata");
    # Move the test file into a correct location.
    assert_script_run("cp openqa_testdata/documents/evince.pdf Documents");
}

sub run {
    my $self = shift;
    # Switch to console
    $self->root_console(tty => 3);
    # Perform git test
    check_and_install_git();
    # Download the test data
    download_testdata();
    # Exit the terminal
    desktop_vt;

    # Start the application
    menu_launch_type("evince");
    # Check that is started
    assert_screen 'apps_run_dviewer';

    # Open the test file to create a starting point for the other Evince tests.
    # Click on Open button to open the File Open Dialog
    assert_and_click("evince_open_file_dialog", button => "left", timeout => 30);

    if (get_var("CANNED")) {
        # open the Documents folder.
        assert_and_click("evince_documents", button => "left", timeout => 30);
    }

    # Select the evince.pdf file.
    assert_and_click("evince_file_select_pdf", button => "left", timeout => 30);

    # Click the Open button to open the file
    assert_and_click("gnome_button_open", button => "left", timeout => 30);

    # Fullsize the Evince window.
    send_key("super-up");

    # Check that the file has been successfully opened.
    assert_screen("evince_file_opened");
}

sub test_flags {
    return {fatal => 1, milestone => 1};
}

1;

# vim: set sw=4 et:
