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

use testapi qw(send_key type_string);

sub init() {
    my ($self) = @_;

    $self->SUPER::init();
}

sub x11_start_program($$$) {
    my ($self, $program, $timeout, $options) = @_;
    # TODO: take screenshots of every goddamn 'run command' dialog in
    # every goddamn desktop and keep them updated forever
    send_key "alt-f2";
    sleep 3;
    type_string $program;
    sleep 1;
    send_key "ret", 1;
}

1;
# vim: set sw=4 et:
