use base "fedoralog";
use strict;
use testapi;


sub run {
    my $self = shift;

    $self->boot_to_login_screen();
    $self->root_console(tty=>3);

    assert_screen "console_f22_installed";
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
