use base "basetest";
use strict;
use testapi;
use utils;

sub run {
    my $self = shift;
    # If UPGRADE is set, we have to wait for the entire upgrade
    my $wait_time = 300;
    $wait_time = 6000 if (get_var("UPGRADE"));

    # handle bootloader, if requested
    if (get_var("GRUB_POSTINSTALL")) {
        do_bootloader(postinstall=>1, params=>get_var("GRUB_POSTINSTALL"), timeout=>$wait_time);
        $wait_time = 180;
    }

    # Wait for the text login
    boot_to_login_screen(timeout => $wait_time);

    # do user login unless USER_LOGIN is set to string 'false'
    unless (get_var("USER_LOGIN") eq "false") {
        console_login(user=>get_var("USER_LOGIN", "test"), password=>get_var("USER_PASSWORD", "weakpassword"));
    }
    if (get_var("ROOT_PASSWORD")) {
        console_login(user=>"root", password=>get_var("ROOT_PASSWORD"));
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
