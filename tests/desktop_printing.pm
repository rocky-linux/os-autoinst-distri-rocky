use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # Prepare the environment:
    #
    # Become root
    $self->root_console(tty=>3);

    # Create a text file with content to print
    script_run  "cd /home/test/";
    assert_script_run  "echo 'A quick brown fox jumps over a lazy dog.' > testfile.txt";
    script_run "chmod 666 testfile.txt";
    # Install the Cups-PDF package to use the Cups-PDF printer
    assert_script_run "dnf -y install cups-pdf", 180;
    # Leave the root terminal and switch back to desktop.
    desktop_vt();
    my $desktop = get_var("DESKTOP");
    # some simple variances between desktops. defaults are for GNOME
    my $editor = "gedit";
    my $viewer = "evince";
    my $maximize = "super-up";
    if ($desktop eq "kde") {
        $editor = "kwrite";
        $viewer = "okular";
        $maximize = "super-pgup";
    }

    # Open the text editor and print the file.
    wait_screen_change { send_key "alt-f2"; };
    wait_still_screen(stilltime=>5, similarity_level=>45);
    type_very_safely "$editor /home/test/testfile.txt\n";
    wait_still_screen(stilltime=>5, similarity_level=>44);
    # Print the file using the Cups-PDF printer
    send_key "ctrl-p";
    wait_still_screen(stilltime=>5, similarity_level=>45);
    if ($desktop eq 'gnome') {
        assert_and_click "printing_select_pdfprinter";
    }
    else {
        # It seems that on newly installed KDE systems with no
        # printer,  the Cups-PDF printer is already pre-selected.
        # We only check that it is correct.
        assert_screen "printing_pdfprinter_ready";
    }
    wait_still_screen(stilltime=>2, similarity_level=>45);
    assert_and_click "printing_print";
    # Exit the application
    send_key "alt-f4";
    # Wait out confirmation on GNOME
    if (check_screen "printing_print_completed", 1) {
        sleep 30;
    }

    # Open the pdf file and check the print
    send_key "alt-f2";
    wait_still_screen(stilltime=>5, similarity_level=>45);
    type_safely "$viewer /home/test/Desktop/testfile.pdf\n";
    wait_still_screen(stilltime=>5, similarity_level=>45);
    # Resize the window, so that the size of the document fits the bigger space
    # and gets more readable.
    send_key $maximize;
    wait_still_screen(stilltime=>2, similarity_level=>45);
    # make sure we're at the start of the document
    send_key "ctrl-home" if ($desktop eq "kde");
    # Check the printed pdf.
    assert_screen "printing_check_sentence";
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
