use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    $self->root_console(tty=>3);
    # check there are no AVCs. We use ! because this returns 1
    validate_script_output '! ausearch -m avc -ts yesterday 2>&1', sub { $_ =~ m/<no matches>/ };
    # check there are no crashes
    validate_script_output '! coredumpctl list 2>&1', sub { $_ =~ m/No coredumps found/ };
}

sub test_flags {
    # without anything - rollback to 'lastgood' snapshot if failed
    # 'fatal' - whole test suite is in danger if this fails
    # 'milestone' - after this test succeeds, update 'lastgood'
    # 'important' - if this fails, set the overall state to 'fail'
    return {};
}

1;

# vim: set sw=4 et:
