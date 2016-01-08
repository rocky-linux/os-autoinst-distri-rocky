use base "installedtest";
use strict;
use testapi;

sub run {
    my $self=shift;
    # wait for boot to complete
    $self->boot_to_login_screen("", 30);
    # switch to TTY3 for both, graphical and console tests
    $self->root_console(tty=>3);
    # we could make this slightly more 'efficient' by assuming sshd
    # is always going to be enabled/running at first, but it's safer
    # to force an expected starting state.
    script_run "systemctl stop sshd.service";
    script_run "systemctl disable sshd.service";
    script_run "reboot";
    $self->boot_to_login_screen("", 30);
    $self->root_console(tty=>3);
    validate_script_output 'systemctl is-enabled sshd.service', sub { $_ =~ m/disabled/ };
    validate_script_output 'systemctl is-active sshd.service', sub { $_ =~ m/inactive/ };
    validate_script_output 'ps -C sshd', sub { $_ !~ m/sshd/ };
    script_run "systemctl start sshd.service";
    validate_script_output 'systemctl is-enabled sshd.service', sub { $_ =~ m/disabled/ };
    validate_script_output 'systemctl is-active sshd.service', sub { $_ =~ m/active/ };
    validate_script_output 'ps -C sshd', sub { $_ =~ m/sshd/ };
    script_run "systemctl stop sshd.service";
    validate_script_output 'systemctl is-enabled sshd.service', sub { $_ =~ m/disabled/ };
    validate_script_output 'systemctl is-active sshd.service', sub { $_ =~ m/inactive/ };
    validate_script_output 'ps -C sshd', sub { $_ !~ m/sshd/ };
    script_run "systemctl enable sshd.service";
    validate_script_output 'systemctl is-enabled sshd.service', sub { $_ =~ m/enabled/ };
    validate_script_output 'systemctl is-active sshd.service', sub { $_ =~ m/inactive/ };
    validate_script_output 'ps -C sshd', sub { $_ !~ m/sshd/ };
    script_run "reboot";
    $self->boot_to_login_screen("", 30);
    $self->root_console(tty=>3);
    validate_script_output 'systemctl is-enabled sshd.service', sub { $_ =~ m/enabled/ };
    validate_script_output 'systemctl is-active sshd.service', sub { $_ =~ m/active/ };
    validate_script_output 'ps -C sshd', sub { $_ =~ m/sshd/ };
    script_run "systemctl disable sshd.service";
    script_run "reboot";
    $self->boot_to_login_screen("", 30);
    $self->root_console(tty=>3);
    validate_script_output 'systemctl is-enabled sshd.service', sub { $_ =~ m/disabled/ };
    validate_script_output 'systemctl is-active sshd.service', sub { $_ =~ m/inactive/ };
    validate_script_output 'ps -C sshd', sub { $_ !~ m/sshd/ };
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
