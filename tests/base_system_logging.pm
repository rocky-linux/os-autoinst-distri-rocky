use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty => 3);
    # Check that journalctl DOESN'T output "No entries". This is also the case when journal files are missing.
    # NOTE: We are quietly assuming that something was logged in journal in last 30 minutes. Should be boot log,
    # switch to TTY3 etc.
    assert_script_run '! journalctl -aeb --since "30 minutes ago" | grep "\-\- No entries \-\-" -q';
    # if rsyslog package is installed (e. g. Server edition), /var/log/secure should exist and be nonempty
    assert_script_run '(! rpm --quiet -q rsyslog) || [ -s /var/log/secure ]';
}


sub test_flags {
    return {fatal => 1};
}

1;

# vim: set sw=4 et:
