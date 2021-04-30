use base "installedtest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    bypass_1691487 unless (get_var("DESKTOP"));
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    my @unwanteds;
    my $subv = get_var("SUBVARIANT");
    if ($subv eq "Workstation") {
        @unwanteds = ("gtk2");
    }
    for my $unwanted (@unwanteds) {
        assert_script_run "! rpm -q $unwanted";
    }
}


sub test_flags {
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
