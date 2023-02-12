use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    if (not(check_screen "root_console", 0)) {
        $self->root_console(tty => 3);
    }
    # this only succeeds if the firewall is running
    assert_script_run 'firewall-cmd --state';
    # we need to check that exactly these three services and no others
    # are allowed...but the displayed order is arbitrary.
    validate_script_output 'firewall-cmd --list-services', sub { m/^(cockpit dhcpv6-client ssh|cockpit ssh dhcpv6-client|dhcpv6-client cockpit ssh|dhcpv6-client ssh cockpit|ssh cockpit dhcpv6-client|ssh dhcpv6-client cockpit)$/ };
    validate_script_output 'firewall-cmd --list-ports', sub { m/^$/ };
    validate_script_output 'firewall-cmd --list-protocols', sub { m/^$/ };
}

sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
