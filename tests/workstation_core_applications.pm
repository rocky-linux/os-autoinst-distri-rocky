use base "installedtest";
use strict;
use testapi;
use utils;

# This test collects the results of application registration (presence or absence).

sub run {
    my $self = shift;
    $self->root_console(tty => 3);

    # List of applications, that we want to track for their presence.
    my @core_applications = ("gnome-software", "firefox", "gnome-terminal", "nautilus", "gedit", "gnome-boxes");

    # Evaluate the results, make the log files and pass or fail the entire
    # test suite.
    my $failed;
    foreach my $app (@core_applications) {
        # @utils::application_list here is the list of registered apps
        if (grep { $_ eq $app } @utils::application_list) {
            assert_script_run "echo '$app=passed' >> registered.log";
        }
        else {
            assert_script_run "echo '$app=failed' >> registered.log";
            $failed = 1;
        }
    }
    upload_logs "registered.log", failok => 1;
    die "Some core applications could not be started. Check logs." if ($failed);
}

sub test_flags {
    return {fatal => 1};
}


1;

# vim: set sw=4 et:
