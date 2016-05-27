use base "installedtest";
use strict;
use testapi;

sub run {
    my $self=shift;
    if (get_var("ARCH") eq "arm") {
        # we cannot use boot_to_login_screen, wait_still_screen is unusable during ARM boot (it shows black screen for first few minutes)
        assert_screen "text_console_login", 150;
    } else {
        # wait for boot to complete
        $self->boot_to_login_screen("", 30);
    }
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    validate_script_output 'systemctl --failed', sub { $_ =~ m/0 loaded units/ };
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
