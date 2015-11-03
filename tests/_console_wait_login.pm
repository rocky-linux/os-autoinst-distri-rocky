use base "fedorabase";
use strict;
use testapi;

sub run {
    my $self = shift;

    # If KICKSTART is set, then the wait_time needs to
    #  consider the install time
    my $wait_time = get_var("KICKSTART") ? 1800 : 300;

    # Reboot and wait for the text login
    assert_screen "text_console_login", $wait_time;

    $self->console_login(user=>get_var("USER_LOGIN", "test"), password=>get_var("USER_PASSWORD", "weakpassword"));
    if (get_var("ROOT_PASSWORD")) {
        $self->console_login(user=>"root", password=>get_var("ROOT_PASSWORD"));
    }
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return { fatal => 1, milestone => 1 };
}

1;

# vim: set sw=4 et:
