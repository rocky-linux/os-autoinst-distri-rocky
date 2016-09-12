package fedoradistribution;
use base 'distribution';

# Fedora distribution class

# Distro-specific functions, that are actually part of the API
# (and it's completely up to us to implement them) should be here

# functions that can be reimplemented:
# ensure_installed
# x11_start_program
# become_root
# script_run
# script_sudo
# type_password

# importing whole testapi creates circular dependency, so import inly
# necessary functions from testapi
use testapi qw(send_key type_string wait_idle assert_screen);

sub init() {
    my ($self) = @_;

    $self->SUPER::init();
}

sub x11_start_program {
    my ($self, $program, $timeout, $options) = @_;
    send_key "alt-f2";
    assert_screen "desktop_runner";
    type_string $program, 20;
    wait_idle 5; # because of KDE dialog - SUSE guys are doing the same!
    send_key "ret", 1;
}

sub script_run {
    my ($self, $program, $timeout) = @_;

    type_string $program;
    send_key "ret", $timeout;
}

1;
# vim: set sw=4 et:
