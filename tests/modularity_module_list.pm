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
    my $module_count = scalar @modules;

    my $flavor = get_var('FLAVOR', 'minimal-iso');
    my $packageset = get_var('PACKAGE_SET', 'minimal');

    if ($flavor eq 'boot-iso') {
        die "There seem to be enabled modules when the list should be empty." unless ($module_count == 0);
    } elsif ($flavor eq 'minimal-iso') {
        if ($packageset eq 'minimal') {
            die "There seem to be enabled modules when the list should be empty." unless ($module_count == 0);
        } elsif ($packageset eq 'server') {
            die "There seem to be enabled modules when the list should be empty." unless ($module_count == 0);
        }
    } elsif ($flavor eq 'dvd-iso' || $flavor eq 'universal') {
        if ($packageset eq 'minimal') {
            die "Enabled modules ($module_count) is not equal to the default (1)." unless (scalar @modules == 1);
        } elsif ($packageset eq 'server') {
            die "Enabled modules ($module_count) is not equal to the default (2)." unless (scalar @modules == 2);
        } elsif ($packageset eq 'graphical-server') {
            die "Enabled modules ($module_count) is not equal to the default (9)." unless (scalar @modules == 9);
        } elsif ($packageset eq 'workstation') {
            die "Enabled modules ($module_count) is not equal to the default (6)." unless (scalar @modules == 6);
        } elsif ($packageset eq 'virtualization-host') {
            die "Enabled modules ($module_count) is not equal to the default (2)." unless (scalar @modules == 2);
        }
    } else {
        die "Enabled modules ($module_count) is not equal to the default (2)." unless (scalar @modules == 2);
    }

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
