use base "anacondatest";
use strict;
use testapi;

sub run {
    my $self = shift;
    $self->root_console();
    upload_logs '/tmp/memory.dat';
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
