use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # do the 'repo setup' steps, which set up a repo containing the
    # update packages and run 'dnf update'
    $self->root_console(tty=>3);
    repo_setup;
    # upload the log of installed packages which repo_setup created
    # we do this here and not in repo_setup because this is the best
    # place to make sure it happens once and only once per job
    upload_logs "/var/log/updatepkgs.txt";
    # reboot, in case any of the updates need a reboot to apply
    script_run "reboot", 0;
}

sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
