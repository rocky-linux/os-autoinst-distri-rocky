use base "fedorabase";
use strict;
use testapi;

sub run {
    my $self = shift;
    # If KICKSTART is set, then the wait_time needs to consider the
    # install time. if UPGRADE, we have to wait for the entire upgrade
    my $wait_time = 300;
    $wait_time = 1800 if (get_var("KICKSTART"));
    $wait_time = 6000 if (get_var("UPGRADE"));

    # handle bootloader, if requested
    if (get_var("GRUB_POSTINSTALL")) {
        $self->do_bootloader(postinstall=>1, params=>get_var("GRUB_POSTINSTALL"), timeout=>$wait_time);
        $wait_time = 180;
    }

    # Wait for the text login
    assert_screen "text_console_login", $wait_time;

    # do user login unless USER_LOGIN is set to string 'false'
    unless (get_var("USER_LOGIN") eq "false") {
        $self->console_login(user=>get_var("USER_LOGIN", "test"), password=>get_var("USER_PASSWORD", "weakpassword"));
    }
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
