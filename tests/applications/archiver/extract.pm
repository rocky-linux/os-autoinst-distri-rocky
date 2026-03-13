use base "installedtest";
use strict;
use testapi;
use utils;

# This script will take a newly created archive and will move it into
# another folder, where it will be extracted and checked.


sub run {
    my $self = shift;
    my $username = get_var("USER_LOGIN") // "test";
    # We are already in the correct directory, so let's just
    # select the newly archived file, that should be there.
    assert_and_click("archiver_archive_created");
    send_key("ctrl-x");
    # Go to the Picture folder.
    assert_and_click("gnome_open_location_pictures");
    # Paste it there.
    send_key("ctrl-v");
    # Assert that a file has been created in that directory (it may take some time)
    assert_screen("archiver_archive_created");
    # Right click onto it
    click_lastmatch(button => 'right');
    # Select to Extract the content
    assert_and_click("archiver_context_extract");
    # Assert that the extracted folder appeared in that location.
    assert_screen("archiver_archive_extracted");

    # Go to console for further testing.
    $self->root_console(tty => 3);
    # The archive has been removed from the original location.
    assert_script_run("! ls /home/$username/Documents/archived_files.tar.xz");
    # The archive has been put into a new location.
    assert_script_run("ls /home/$username/Pictures/archived_files.tar.xz");
    # The content was extracted.
    #assert_script_run("ls /home/$username/Pictures/archived_files");
    # All nine files are there.
    validate_script_output("ls /home/$username/Pictures/archived_files/* | wc -l", qr/9/);

}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
