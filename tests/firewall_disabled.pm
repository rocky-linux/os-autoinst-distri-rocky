use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    if (not(check_screen "root_console", 0)) {
        $self->root_console(tty => 3);
    }
    # this asserts that the command fails (which it does when fw is not running)
    assert_script_run '! firewall-cmd --state';
    # check there are no 'REJECT' rules in iptables
    validate_script_output 'iptables -L -v', sub { $_ !~ m/.*REJECT.*/s };
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
