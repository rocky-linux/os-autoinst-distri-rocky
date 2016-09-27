use base "installedtest";
use strict;
use testapi;

sub run {
    my $self = shift;
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    my $output = script_output 'systemctl --failed';
    if ($output =~ /1 loaded units/ && $output =~ /mcelog.service/) {
        record_soft_failure;
    } elsif (! $output =~ /0 loaded units/) {
        die "Services other than mcelog failed to load";
    }
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
