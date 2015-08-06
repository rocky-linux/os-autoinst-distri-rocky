use base "installedtest";
use strict;
use testapi;


sub run {
    my $self = shift;
    my $password = get_var("USER_PASSWORD", "weakpassword");

    # wait for GDM to appear
    $self->boot_to_login_screen("graphical_login", 20);

    # login as normal user
    send_key "ret";
    assert_screen "graphical_login_input";
    type_string $password;
    send_key "ret";
    # wait until desktop appears
    assert_screen "graphical_desktop_clean", 30;
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
