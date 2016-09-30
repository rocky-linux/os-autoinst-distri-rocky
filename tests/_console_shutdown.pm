use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # this shutdown code is only to make sure the guest disk is clean
    # before uploading an image of it, we're really not "testing"
    # shutdown here. So to keep things simple and reliable, we do not
    # use the desktops' graphical shutdown methods, we just go to a
    # console and run 'poweroff'. We can write separate tests for
    # properly testing shutdown/reboot/log out from desktops.
    $self->root_console(tty=>3);
    script_run("poweroff", 0);
    assert_shutdown;
}

# this is not 'fatal' or 'important' as all wiki test cases are passed
# even if shutdown fails. we should have a separate test for shutdown/
# logout/reboot stuff, might need some refactoring.
sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'norollback' - don't rollback if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return {'norollback' => 1};
}

1;

# vim: set sw=4 et:
