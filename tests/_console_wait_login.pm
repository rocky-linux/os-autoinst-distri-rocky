use base "installedtest";
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
        $wait_time = 240;
    }

    # handle initial-setup, if we're expecting it (ARM disk image)
    if (get_var("INSTALL_NO_USER")) {
        console_initial_setup;
    }

    # Wait for the text login
    boot_to_login_screen(timeout => $wait_time);

    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);

    # do user login unless USER_LOGIN is set to string 'false'
    unless (get_var("USER_LOGIN") eq "false") {
        # this avoids us waiting 90 seconds for a # to show up
        my $origprompt = $testapi::distri->{serial_term_prompt};
        $testapi::distri->{serial_term_prompt} = '$ ';
        console_login(user=>get_var("USER_LOGIN", "test"), password=>get_var("USER_PASSWORD", "weakpassword"));
        $testapi::distri->{serial_term_prompt} = $origprompt;
    }
    if (get_var("ROOT_PASSWORD")) {
        console_login(user=>"root", password=>get_var("ROOT_PASSWORD"));
    }
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;

# vim: set sw=4 et:
