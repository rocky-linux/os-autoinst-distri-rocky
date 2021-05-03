use base "installedtest";
use strict;
use modularity;
use testapi;
use utils;

sub run {
    my $self=shift;
    # switch to tty and login as root
    $self->root_console(tty=>3);

    # The test case will check that dnf has modular functions and that
    # it is possible to invoke modular commands to work with modularity.

    # Check that modular repositories are installed and enabled.
    # If the repository does not exist, the output of the command is empty.
    if (lc(get_var('VERSION')) eq "rawhide") {
        my $mrawhide_output = script_output("dnf repolist --enabled rawhide-modular");
        die "The rawhide-modular repo seems not to be installed." unless (length $mrawhide_output);
    }
    else {
        my $mfedora_output = script_output("dnf repolist --enabled fedora-modular");
        die "The fedora-modular repo seems not to be installed." unless (length $mfedora_output);
        my $mupdates_output = script_output("dnf repolist --enabled updates-modular");
        die "The updates-modular repo seems not to be installed." unless (length $mupdates_output);
    }

    # Check that modularity works and dnf can list the modules.
    my $modules = script_output('dnf module list --disablerepo=updates-modular --disablerepo=updates-testing-modular', timeout => 270);
    my @modules = parse_module_list($modules);
    die "The module list seems to be empty when it should not be." if (scalar @modules == 0);

    # Check that modularity works and dnf can list the modules
    # with the -all option.
    $modules = script_output('dnf module list --all --disablerepo=updates-modular --disablerepo=updates-testing-modular', timeout => 270);
    @modules = parse_module_list($modules);
    die "The module list seems to be empty when it should not be." if (scalar @modules == 0);

    # Check that dnf lists the enabled modules.
    $modules = script_output('dnf module list --enabled', timeout => 270);
    @modules = parse_module_list($modules);
    die "There seem to be enabled modules when the list should be empty." unless (scalar @modules == 0);

    # Check that dnf lists the disabled modules.
    $modules = script_output('dnf module list --disabled', timeout => 270);
    @modules = parse_module_list($modules);
    die "There seem to be disabled modules when the list should be empty." unless (scalar @modules == 0);

    # Check that dnf lists the installed modules.
    $modules = script_output('dnf module list --installed', timeout => 270);
    @modules = parse_module_list($modules);
    die "There seem to be installed modules when the list should be empty." unless (scalar @modules == 0);
}


1;

# vim: set sw=4 et:
