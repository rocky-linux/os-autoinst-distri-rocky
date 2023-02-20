use base "installedtest";
use strict;
use modularity;
use testapi;
use utils;

sub run {
    my $self = shift;
    # switch to tty and login as root
    $self->root_console(tty => 3);

    # Install a Ruby module.
    my $name = "nodejs";
    my $stream = "14";
    my $profile = "common";
    assert_script_run("dnf module install -y $name:$stream/$profile");

    # Check that it is listed in the installed list.
    my $enabled = script_output('dnf module list --installed');
    my @enabled_modules = parse_module_list($enabled);
    my $found = is_listed($name, $stream, \@enabled_modules);
    unless ($found) {
        die "The installed module is not listed in the list of installed modules but it should be.";
    }

    # Check that it is listed in the enabled list.
    my $disabled = script_output('dnf module list --enabled');
    my @disabled_modules = parse_module_list($disabled);
    $found = is_listed($name, $stream, \@disabled_modules);
    unless ($found) {
        die "The installed module is not listed in the list of enabled modules but it should be.";
    }

    # Remove the module again.
    assert_script_run("dnf module remove -y $name:$stream");

    # Check that it is not listed in the installed list.
    my $enabled = script_output('dnf module list --installed');
    my @enabled_modules = parse_module_list($enabled);
    my $found = is_listed($name, $stream, \@enabled_modules);
    if ($found) {
        die "The installed module is listed in the list of installed modules but it should not be.";
    }
}

1;

# vim: set sw=4 et:
