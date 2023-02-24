use base "installedtest";
use strict;
use testapi;
use utils;
use modularity;

sub run {
    my $self = shift;
    # switch to tty and login as root
    $self->root_console(tty => 3);

    # Update the system
    assert_script_run('dnf update -y');

    # Enable and install the nodejs module, stream 11.
    assert_script_run('dnf module install -y nodejs:15');

    # Update the system without modular repos.
    assert_script_run('dnf update --disablerepo=\*modular -y');

    # Check that the same version is listed in the installed modules.
    my $installed = script_output('dnf module list --installed');
    my @installed_modules = parse_module_list($installed);
    my $found = is_listed("nodejs", "15", \@installed_modules);
    unless ($found) {
        die "The expected module and version has not been found. The version might have been incorrectly changed by the upgrade command.";
    }
}

1;

# vim: set sw=4 et:
