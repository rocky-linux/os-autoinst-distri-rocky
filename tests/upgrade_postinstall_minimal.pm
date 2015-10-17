use base "installedtest";
use strict;
use testapi;


sub run {
    my $self = shift;

    # try to login, check whether target release is installed
    $self->boot_to_login_screen();
    $self->root_console(tty=>3);
    $self->check_release(lc(get_var('VERSION')));
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
