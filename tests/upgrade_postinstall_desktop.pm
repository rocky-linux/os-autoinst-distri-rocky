use base "installedtest";
use strict;
use testapi;


sub run {
    my $self = shift;
    my $password = get_var("USER_PASSWORD", "weakpassword");

    # wait for DM to appear
    $self->boot_to_login_screen("graphical_login", 20);

    # login as normal user
    if (get_var("DESKTOP") eq 'gnome') {
        send_key "ret";
    }
    assert_screen "graphical_login_input";
    type_string $password;
    send_key "ret";
    # wait until desktop appears
    assert_screen "graphical_desktop_clean", 60;
    # check an upgrade actually happened (and we can log into a console)
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
