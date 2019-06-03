use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self=shift;
    bypass_1691487 unless (get_var("DESKTOP"));
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    validate_script_output 'getenforce', sub { $_ =~ m/Enforcing/ };
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
