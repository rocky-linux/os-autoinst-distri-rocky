use base "anacondatest";
use strict;
use testapi;

sub run {
    my $self = shift;
    $self->root_console();
    upload_logs '/tmp/memory.dat';
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1 };
}

1;

# vim: set sw=4 et:
