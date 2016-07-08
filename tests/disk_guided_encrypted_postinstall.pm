use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    my $wait_time = 300;
    # if we're running an upgrade, we must wait for the entire upgrade
    # process to run
    $wait_time = 6000 if (get_var("UPGRADE"));
    # decrypt disks during boot
    $self->boot_decrypt($wait_time);
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
