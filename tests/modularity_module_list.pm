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

    # Check that dnf lists the enabled modules.
    # NOTE: In Rocky the baseos and appstream default repos include and add modules in the
    #       default installation where in Fedora all modules are in separate modular repos.
    #       Until we figure out how to keep track of the count of expected enabled modular
    #       packages this will need to assume what appears to be the default in minimal.
    my $modules = script_output('dnf module list --enabled', timeout => 270);
    my @modules = parse_module_list($modules);
    die "Enabled modules is less than the default (3)." unless (scalar @modules < 3);
    die "Enabled modules is greater than the default (3)." unless (scalar @modules > 3);

    # More advanced... loop over default modules and check them directly. The is_listed
    # bit comes from modularity_enable_disable_module.pm

    #perl                5.26   [d][e]
    #perl-IO-Socket-SSL  2.066  [d][e]
    #perl-libwww-perl    6.34   [d][e]
    #my @enabled_modules = parse_module_list($enabled);
    #unless (is_listed($name, $stream, \@enabled_modules)) {
    #    die "The enabled module is not listed in the list of enabled modules but it should be.";
    #}

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
